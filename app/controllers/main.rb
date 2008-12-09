require File.join( File.dirname(__FILE__), '..', '..', 'lib', 'merb_models' )
require File.join( File.dirname(__FILE__), '..', '..', 'lib', 'metaid' )

class MerbAdmin::Main < MerbAdmin::Application
  before :find_models
  before :find_model, :only => ['index', 'show', 'edit', 'new']
  before :find_object, :only => ['show','edit']

  def all() render; end

  def index() render; end

  def show() render; end

  def edit() render; end

  def new() render; end

  def create
    # move all association data into separate array to add
    # after model is created
    associations = @model.has_many_associations.collect { |a|
      [ a, params['model'].delete( a[:name] ) ]
    }

    # zero out all blank fields
    params[:model].each { |k,v| params[:model][k] = nil if v.blank? }

    @model = @model.model.new(params[:model])
    if @model.save
      associations.each { |a, ids| update_has_many_association( a, @model, ids ) }
      redirect url( "scaffold_#{self.class.Model.singular_name}", @model)
    else
      render :new
    end
  end

  def update
    params[:model].each { |k,v| params[:model][k] = nil if v.blank? }

    @model = find_first( self.class.Model, params[:id] )
    raise NotFound unless @model

    associations = self.class.Model.scaf_has_manys.collect { |a|
      [ a, params['model'].delete( a.name ) ]
    }

    if @model.update_attributes(params[:model])
      associations.each { |a, ids| update_has_many_association( a, @model, ids ) }
      redirect url( "scaffold_#{self.class.Model.singular_name}", @model)
    else
      raise BadRequest
    end
  end

  def destroy
    @model = find_first( self.class.Model, params[:id] )
    raise NotFound unless @model
    if delete( @model )
      redirect url( "scaffold_#{self.class.Model.plural_name}" )
    else
      raise BadRequest
    end
  end

  private

  def find_models
    @models = MerbAdmin::Models.all
  end

  def find_model
    model_name = params[:model].camel_case
    @model = MerbAdmin::Models.new( model_name )
  end

  def find_object
    @object = @model.find( params[:id] )
  end

  def clear_association( object, assoc )
    rel = object.send( assoc.name )
    case
      when self.class.Model.superclass == ActiveRecord::Base then rel.clear
      when self.class.Model.superclass == DataMapper::Base   then rel.nullify_association
      when self.class.Model.include?( DataMapper::Resource ) then rel.nullify_association
    end
    rel
  end

  def update_has_many_association( assoc, model, ids )
    # remove all of the associated items
    rel = clear_association( model, assoc )

    # add all of the objects to the relationship
    for obj in find_all( assoc.klass, :conditions => ["#{ assoc.klass.primary_key } in (?)", ids] )
      rel << obj
    end
    model.save
  end

end