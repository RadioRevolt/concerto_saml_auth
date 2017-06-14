require_dependency "concerto_saml_auth/application_controller"

module ConcertoSamlAuth
  class OmniauthCallbackController < ApplicationController

    def cas_auth
      saml_hash = request.env["omniauth.auth"]
      user = find_from_omniauth(saml_hash)

      if !user
        # Redirect showing flash notice with errors
        redirect_to "/"
      elsif user.persisted?
        flash.notice = "Signed in through SAML"
        session["devise.user_attributes"] = user.attributes
        sign_in user
        redirect_to "/"
      else
        flash.notice = "Signed in through SAML"
        session["devise.user_attributes"] = user.attributes
        sign_in user
        redirect_to "/"
      end
    end

  end
end
