require_dependency "concerto_saml_auth/application_controller"

module ConcertoSamlAuth
  class OmniauthCallbackController < ApplicationController

    # We will be receiving a POST request initiated by the identity provider.
    # To check its authenticity, OneLogin SAML will check its signature.
    # Therefore, we must skip the CSRF protection, since it interferes with
    # normal operation (it disconnects us from the session, basically).
    skip_before_action :verify_authenticity_token

    def saml_auth
      saml_hash = request.env["omniauth.auth"]
      result = find_from_omniauth(saml_hash)

      if !result
        # Redirect showing flash notice with errors
        redirect_to "/"
      else
        user = result[:user]
        user_existed = result[:existed]
        session["devise.user_attributes"] = user.attributes
        sign_in user
        if user_existed
          flash[:notice] = "Signed in as #{user.first_name} #{user.last_name}"
          redirect_to "/"
        else
          flash[:notice] = "Welcome to Concerto, #{user.first_name} #{user.last_name}! Have a look at the options"
          redirect_to "/manage/users/#{user.id}/edit"
        end
      end
    end

  end
end
