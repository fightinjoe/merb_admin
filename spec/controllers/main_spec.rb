require File.dirname(__FILE__) + '/../spec_helper'

describe "MerbAdmin::Main (controller)" do
  
  # Feel free to remove the specs below
  
  before :all do
    Merb::Router.prepare { add_slice(:MerbAdmin) } if standalone?
  end
  
  after :all do
    Merb::Router.reset! if standalone?
  end
  
  it "should have access to the slice module" do
    controller = dispatch_to(MerbAdmin::Main, :index)
    controller.slice.should == MerbAdmin
    controller.slice.should == MerbAdmin::Main.slice
  end
  
  it "should have an index action" do
    controller = dispatch_to(MerbAdmin::Main, :index)
    controller.status.should == 200
    controller.body.should contain('MerbAdmin')
  end
  
  it "should work with the default route" do
    controller = get("/merb_admin/main/index")
    controller.should be_kind_of(MerbAdmin::Main)
    controller.action_name.should == 'index'
  end
  
  it "should work with the example named route" do
    controller = get("/merb_admin/index.html")
    controller.should be_kind_of(MerbAdmin::Main)
    controller.action_name.should == 'index'
  end
    
  it "should have a slice_url helper method for slice-specific routes" do
    controller = dispatch_to(MerbAdmin::Main, 'index')
    
    url = controller.url(:merb_admin_default, :controller => 'main', :action => 'show', :format => 'html')
    url.should == "/merb_admin/main/show.html"
    controller.slice_url(:controller => 'main', :action => 'show', :format => 'html').should == url
    
    url = controller.url(:merb_admin_index, :format => 'html')
    url.should == "/merb_admin/index.html"
    controller.slice_url(:index, :format => 'html').should == url
    
    url = controller.url(:merb_admin_home)
    url.should == "/merb_admin/"
    controller.slice_url(:home).should == url
  end
  
  it "should have helper methods for dealing with public paths" do
    controller = dispatch_to(MerbAdmin::Main, :index)
    controller.public_path_for(:image).should == "/slices/merb_admin/images"
    controller.public_path_for(:javascript).should == "/slices/merb_admin/javascripts"
    controller.public_path_for(:stylesheet).should == "/slices/merb_admin/stylesheets"
    
    controller.image_path.should == "/slices/merb_admin/images"
    controller.javascript_path.should == "/slices/merb_admin/javascripts"
    controller.stylesheet_path.should == "/slices/merb_admin/stylesheets"
  end
  
  it "should have a slice-specific _template_root" do
    MerbAdmin::Main._template_root.should == MerbAdmin.dir_for(:view)
    MerbAdmin::Main._template_root.should == MerbAdmin::Application._template_root
  end

end