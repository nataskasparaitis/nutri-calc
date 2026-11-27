# frozen_string_literal: true

class Users::Authenticate
  include Interactor::Initializer

  initialize_with_keyword_params :email, :password

  def run
    User.authenticate_by(email: email.to_s, password: password.to_s) || raise(Users::Errors::InvalidCredentials)
  end
end
