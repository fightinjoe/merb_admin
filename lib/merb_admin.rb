if defined?(Merb::Plugins)

  $:.unshift File.dirname(__FILE__)

  load_dependency 'merb-slices'
  Merb::Plugins.add_rakefiles "merb_admin/merbtasks", "merb_admin/slicetasks", "merb_admin/spectasks"

  # Register the Slice for the current host application
  Merb::Slices::register(__FILE__)
  
  # Slice configuration - set this in a before_app_loads callback.
  # By default a Slice uses its own layout, so you can swicht to 
  # the main application layout or no layout at all if needed.
  # 
  # Configuration options:
  # :layout - the layout to use; defaults to :merb_admin
  # :mirror - which path component types to use on copy operations; defaults to all
  Merb::Slices::config[:merb_admin][:layout] ||= :merb_admin
  
  # All Slice code is expected to be namespaced inside a module
  module MerbAdmin
    
    # Slice metadata
    self.description = "MerbAdmin is a chunky Merb slice!"
    self.version = "0.0.1"
    self.author = "Engine Yard"
    
    # Stub classes loaded hook - runs before LoadClasses BootLoader
    # right after a slice's classes have been loaded internally.
    def self.loaded
    end
    
    # Initialization hook - runs before AfterAppLoads BootLoader
    def self.init
    end
    
    # Activation hook - runs after AfterAppLoads BootLoader
    def self.activate
    end
    
    # Deactivation hook - triggered by Merb::Slices.deactivate(MerbAdmin)
    def self.deactivate
    end
    
    # Setup routes inside the host application
    #
    # @param scope<Merb::Router::Behaviour>
    #  Routes will be added within this scope (namespace). In fact, any 
    #  router behaviour is a valid namespace, so you can attach
    #  routes at any level of your router setup.
    #
    # @note prefix your named routes with :merb_admin_
    #   to avoid potential conflicts with global named routes.
    def self.setup_router(scope)
      # example of a named route
      # scope.match('index(.:format)').to(:controller => 'main', :action => 'index').name(:index)
      # the slice is mounted at /merb_admin - note that it comes before default_routes
      scope.match('/').to(:controller => 'main', :action => 'all').name(:home)
      # enable slice-level default routes by default
      scope.match('/:model(/:action(/:id(.:format)))').to(:controller => 'main').name(:model)
    end
    
  end
  
  # Setup the slice layout for MerbAdmin
  #
  # Use MerbAdmin.push_path and MerbAdmin.push_app_path
  # to set paths to merb_admin-level and app-level paths. Example:
  #
  # MerbAdmin.push_path(:application, MerbAdmin.root)
  # MerbAdmin.push_app_path(:application, Merb.root / 'slices' / 'merb_admin')
  # ...
  #
  # Any component path that hasn't been set will default to MerbAdmin.root
  #
  # Or just call setup_default_structure! to setup a basic Merb MVC structure.
  MerbAdmin.setup_default_structure!
  
  # Add dependencies for other MerbAdmin classes below. Example:
  # dependency "merb_admin/other"
  
end