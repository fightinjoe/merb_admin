require 'paginator'

module MerbAdmin; class Models
  MODEL_REGEXP = %r{^class ([\w\d_\-:]+).*?$}

  # Returns all models for a given Merb app
  def self.all
    return @models if @models

    @models ||= []
    file_pattern = Merb.glob_for(:model) || '*.rb'
    Dir.glob( Merb.dir_for(:model) / file_pattern ).each { |f|
      for m in File.read(f).scan( MODEL_REGEXP ).flatten
        model = lookup( m )
        @models << new(model) if model
      end
    }
    @models
  end

  # Given a string +model_name+, finds the corresponding model class
  def self.lookup( model_name )
    out = const_get( model_name )
    raise "could not find model #{model_name}" if out.nil?
    return out if out.include?( DataMapper::Resource )
    nil
  end

  attr_accessor :model

  def initialize( model )
    model  = self.class.lookup( model.camel_case ) unless model.is_a?( Class )
    @model = model
    self.extend( GenericSupport )
    case Merb.orm
      when :datamapper then self.extend( DatamapperSupport )
      else raise "Merb AutoScaffold does not currently support the #{ Merb.orm } ORM"
    end
  end

  module GenericSupport
    def singular_name() model.to_s.snake_case.to_sym; end
    def plural_name()   model.to_s.snake_case.pluralize.to_sym; end
    def pretty_name()   model.to_s.snake_case.capitalize.pluralize; end

    def pages
      return @pages if @pages
      @pages = Paginator.new( count, 20) do |offset, per_page|
        find_all( :limit => per_page, :offset => offset )
      end
      @pages
    end
  end

  module DatamapperSupport
    # Returns all properties for a model
    def attributes
      model.properties.collect { |m|
        { :key? => m.key?, :name => m.name, :type => type_lookup( m.type ) }
      }
    end

    def count() model.count; end

    def id() model.id; end

    # helper method for finding all objects in a model class.  Used
    # specifically by #pages for pagination.
    def find_all( opts = {} )
      # opts[:order] ||= [:posted_at.desc, :id.asc]
      model.all( opts )
    end

    # Given the +id+ of an object, finds that object by calling the
    # finder method on the model.
    def find( id )
      model.get( id ).extend( InstanceMethods )
    end

    def has_many_associations
      associations.select { |a| a[:type] == :has_many }
    end

    def has_one_associations
      associations.select { |a| a[:type] == :has_one }
    end

    def belongs_to_associations
      associations.select { |a| a[:type] == :belongs_to }
    end

    # Returns an array of hashes that represent all the associations the
    # model knows about
    def associations
      model.relationships.to_a.collect { |name,rel|
        {
          :name => name.to_s,
          :type => association_type_lookup( rel ), # :has_many, :has_one, or :belongs_to
          :parent_model => rel.parent_model,
          :parent_key   => rel.parent_key.collect { |p| p.name },
          :child_model  => rel.child_model,
          :child_key    => rel.child_key.collect { |p| p.name },
          :remote_rel   => rel.options[:remote_relationship_name],
          :near_rel     => rel.options[:near_relationship_name]
        }
      }
    end

    def association_names
      associations.collect { |a|
        a[:type] == :belongs_to ? a[:parent_name] : a[:child_name]
      }
    end

    private

      def type_lookup(type)
        {
          DataMapper::Types::Serial   => :integer,
          DataMapper::Types::Boolean  => :bool,
          DataMapper::Types::Text     => :text,
          String   => :string,
          Integer  => :integer,
          DateTime => :datetime
        }[ type ] || type
      end

      def association_type_lookup( relationship )
        if    self.model == relationship.parent_model
          relationship.options[:max] > 1 ? :has_many : :has_one
        elsif self.model == relationship.child_model
          :belongs_to
        else
          raise 'unknowny type of association'
        end
      end

    module InstanceMethods
      def clear_association( assoc )
        assoc.clear
      end
    end

  end
end; end