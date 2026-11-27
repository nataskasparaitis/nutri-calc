# frozen_string_literal: true

class Users::Serialize
  include Interactor::Initializer

  initialize_with_keyword_params :user

  def run
    {
      id: user.id,
      email: user.email,
      nickname: user.nickname,
      admin: user.admin
    }
  end
end
