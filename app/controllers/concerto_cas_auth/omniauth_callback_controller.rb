require_dependency "concerto_cas_auth/application_controller"

module ConcertoCasAuth
  class OmniauthCallbackController < ApplicationController

    def cas_auth
      cas_hash = request.env["omniauth.auth"]
      user = find_from_omniauth(cas_hash)

      if !user
        flash.notice = "Failed to sign in with CAS"
        redirect_to "/"
      elsif user.persisted?
        flash.notice = "Signed in through CAS"
        session["devise.user_attributes"] = user.attributes
        sign_in user
        redirect_to "/"
      else 
        flash.notice = "Signed in through CAS"
        session["devise.user_attributes"] = user.attributes
        sign_in user
        redirect_to "/"
      end
    end

  end
end