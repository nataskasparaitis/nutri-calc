# frozen_string_literal: true

class Api::V1::UsersController < ApplicationController
  allow_unauthenticated_access only: :create

  rate_limit to: 10,
    within: 3.minutes,
    only: :create,
    with: :render_too_many_requests

  def create
    user = Users::Register.for(
      email: params.expect(:email),
      nickname: params.expect(:nickname),
      password: params.expect(:password)
    )
    start_new_session_for(user)

    render json: {
      code: Api::ResponseCodes::OK,
      user: Users::Serialize.for(user: user)
    },
    status: :created
  end

  def destroy
    Users::Destroy.for(user: Current.user, id: params.expect(:id))
    terminate_session

    head :no_content
  end
end
