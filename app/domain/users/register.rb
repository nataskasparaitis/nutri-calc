# frozen_string_literal: true

class Users::Register
  include Interactor::Initializer

  initialize_with_keyword_params :email, :nickname, :password

  def run
    User.create!(email: email.to_s, nickname: nickname.to_s, password: password.to_s)
  end
end
