class Api::SessionsController < Api::BaseController
  include Devise::Controllers::Helpers
  acts_as_token_authentication_handler_for User, :except => [:create]
  before_filter :ensure_params_exist

  skip_before_action :verify_authenticity_token

  respond_to :json

  def create
    resource = User.find_for_database_authentication(:email =>params[:user_login][:email])

    return invalid_login_attempt unless resource

    if resource.valid_password?(params[:user_login][:password])
      sign_in("user", resource)
      render :json=> {:success=>true, :auth_token=>resource.authentication_token, :email=>resource.email}
      return
    end
    invalid_login_attempt
  end

  def destroy
    resource = User.where("authentication_token = '#{params[:user_login][:user_token]}' AND
                           email = '#{params[:user_login][:email]}'").first
    resource.authentication_token = nil
    resource.save
    sign_out(resource)
    render :json => {:success=>true}, :status => :ok
  end

  protected
    def ensure_params_exist
      return unless params[:user_login].blank?
      render :json=>{:success=>false, :message=>"missing user_login parameter"}, :status=>422
    end

    def invalid_login_attempt
      warden.custom_failure!
      render :json=> {:success=>false, :message=>"Error with your login or password"}, :status=>401
    end

end
