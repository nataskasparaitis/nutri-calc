# frozen_string_literal: true

class Api::V1::SessionsController < ApplicationController
  allow_unauthenticated_access only: :create

  rate_limit to: 10,
    within: 3.minutes,
    only: :create,
    with: :render_too_many_requests

  def create
    user = Users::Authenticate.for(
      email: params.expect(:email),
      password: params.expect(:password)
    )
    start_new_session_for(user)

    render json: {
      code: Api::ResponseCodes::OK,
      user: Users::Serialize.for(user: user)
    },
    status: :created
  end

  def show
    render json: {
      code: Api::ResponseCodes::OK,
      user: Users::Serialize.for(user: Current.user)
    }
  end

  def destroy
    terminate_session
    head :no_content
  end
end
