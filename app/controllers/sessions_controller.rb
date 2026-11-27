# frozen_string_literal: true

class SessionsController < ApplicationController
  allow_unauthenticated_access only: :create

  rate_limit to: 10,
    within: 3.minutes,
    only: :create,
    with: -> {
      render json: { error: "Too many login attempts, try again later" },
      status: :too_many_requests
    }

  def create
    email, password = params.expect(:email, :password)
    user = User.authenticate_by(email: email.to_s, password: password.to_s)

    if user.present?
      start_new_session_for(user)
      render json: user_json(user), status: :created
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  def show
    render json: user_json(Current.user)
  end

  def destroy
    terminate_session
    head :no_content
  end

  private

  def user_json(user)
    user.as_json(only: %i[id email nickname admin])
  end
end
