class Api::BaseController < ApplicationController
  skip_before_action :verify_authenticity_token
  prepend_before_filter :get_auth_token
  acts_as_token_authentication_handler_for User

  respond_to :xml, :json


  private

    def get_auth_token
      if auth_token = params[:auth_token].blank? && request.headers["X-AUTH-TOKEN"]
        params[:auth_token] = auth_token
      end
    end
end
