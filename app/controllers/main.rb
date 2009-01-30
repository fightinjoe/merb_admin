require File.join( File.dirname(__FILE__), '..', '..', 'lib', 'merb_models' )
require File.join( File.dirname(__FILE__), '..', '..', 'lib', 'metaid' )

class MerbAdmin::Main < MerbAdmin::Application
  before :find_models
  before :find_model, :exclude => ['all']
  before :find_object, :only => ['show','edit', 'update', 'destroy']

  def all() render; end

  def index() render; end

  def show() render; end

  def edit() render; end

  def new() render; end

  def create
    # move all association data into separate array to add
    # after model is created
    associations = @model.has_many_associations.collect { |a|
      [ a, params[:object].delete( a[:name] ) ]
    }

    # zero out all blank fields
    params[:object].each { |k,v| params[:object][k] = nil if v.blank? }

    @object = @model.newInstance( params[:object] )
    if @object.save
      associations.each { |a, ids| update_has_many_association( a, ids ) }
      redirect slice_url( :model, @model.singular_name.to_s, 'show', @object.id )
    else
      debugger
      render :new
    end
  end

  def update
    raise NotFound unless @object

    # nullify any fields that come back empty
    params[:object].each { |k,v| params[:object][k] = nil if v.blank? }

    # find the objects that are being associated with @object
    associations = @model.has_many_associations.collect { |a|
      [ a, params[:object].delete( a[:name] ) ]
    }

    # Update the attributes of the object, then add in any has_many associations
    if @object.update_attributes(params[:object])
      associations.each { |a, ids| update_has_many_association( a, ids ) }
      redirect slice_url( :model, @model.singular_name.to_s, 'show', @object.id )
    else
      render :edit
    end
  end

  def destroy
    raise NotFound unless @object
    if @object.destroy
      redirect slice_url( :model, @model.singular_name.to_s, 'index' )
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

  def update_has_many_association( assoc, ids )
    # remove all of the associated items
    rel = @object.send( assoc[:name] )
    @object.clear_association( rel )

    # add all of the objects to the relationship
    conds = { assoc[:parent_key].first => ids }
    model = MerbAdmin::Models.new( assoc[:child_model] )
    for obj in model.find_all( conds )
      rel << obj
    end

    @object.save
  end

end