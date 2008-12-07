require File.join( File.dirname(__FILE__), '..', '..', 'lib', 'merb_models' )
require File.join( File.dirname(__FILE__), '..', '..', 'lib', 'metaid' )

class MerbAdmin::Main < MerbAdmin::Application
  before :find_models
  before :find_model, :only => ['index', 'show', 'edit']
  before :find_object, :only => ['show','edit']

  def all() render; end

  def index() render; end

  def show() render; end

  def edit() render; end

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

end