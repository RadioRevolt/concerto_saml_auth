module ConcertoSamlAuth

  require 'omniauth'
  require 'omniauth-saml'
  require 'concerto_identity'

  class Engine < ::Rails::Engine
    isolate_namespace ConcertoSamlAuth
    engine_name 'concerto_saml_auth'

    # Define plugin information for the Concerto application to read.
    # Do not modify @plugin_info outside of this static configuration block.
    def plugin_info(plugin_info_class)
      @plugin_info ||= plugin_info_class.new do

        # Add our concerto_saml_auth route to the main application
        add_route("concerto_saml_auth", ConcertoSamlAuth::Engine)

        # View hook to override Devise sign in links in the main application
        add_view_hook "ApplicationController", :signin_hook,
          :partial => "concerto_saml_auth/omniauth_saml/signin"

        # Controller hook to supply a redirect route (example: non public Concerto instances)
        add_controller_hook "ApplicationController", :auth_plugin, :before do
          @auth_url = "/auth/saml"
        end
      end
    end

  end
end
