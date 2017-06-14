Concerto::Application.routes.draw do
  get "/auth/saml/callback", :to => "concerto_saml_auth/omniauth_callback#saml_auth"
end
