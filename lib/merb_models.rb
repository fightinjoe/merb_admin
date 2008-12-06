require 'paginator'

module MerbAdmin; class Models
  MODEL_REGEXP = %r{^class ([\w\d_\-:]+)(.*)?$}

  # Returns all models for a given Merb app
  def self.all
    return @models if @models

    @models ||= []
    Dir.glob( Merb.dir_for(:model) / Merb.glob_for(:model) ).each { |f|
      if File.read(f).match( MODEL_REGEXP )
        model = new( lookup( $1 ) )
        @models << model
      end
    }
    @models
  end

  # Given a string +model_name+, finds the corresponding model class
  def self.lookup( model_name )
    out = const_get( model_name )
    raise "could not find model #{model_name}" if out.nil?
    out
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

    def find_all( opts )
      # opts[:order] ||= [:posted_at.desc, :id.asc]
      model.all( opts )
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
          :type => association_type_lookup( rel ),
          :parent_model => rel.parent_model,
          :parent_key   => rel.parent_key.collect { |p| p.name },
          :child_model  => rel.child_model,
          :child_key    => rel.child_key.collect { |p| p.name }
        }
      }
    end

    private

      def type_lookup(type)
        {
          DataMapper::Types::Serial  => Fixnum,
          DataMapper::Types::Integer => Fixnum,
          DataMapper::Types::Boolean => Boolean,
          DataMapper::Types::Text    => String
        }[ type ] || type
      end

      def association_type_lookup( relationship )
        case self.model
          when relationship.parent_model
            r.options[:max] > 1 ? :has_many : :has_one
          when relationship.child_model then :belongs_to
          else raise 'unknowny type of association'
        end
      end
  end
end; end