# frozen_string_literal: true

class Users::Destroy
  include Interactor::Initializer

  initialize_with_keyword_params :user, :id

  def run
    raise Users::Errors::AccessDenied unless user.id == id.to_i

    user.destroy!
  end
end
