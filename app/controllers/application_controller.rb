class ApplicationController < ActionController::API
  include ActionController::Cookies
  include Authentication

  rescue_from ActionController::ParameterMissing, with: :parameter_missing_handler
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid_handler
  rescue_from Users::Errors::InvalidCredentials, with: :invalid_credentials_handler

  private

  def parameter_missing_handler(exception)
    render_validation_error(base: exception.message)
  end

  def record_invalid_handler(exception)
    render_validation_error(exception.record.errors.messages)
  end

  def invalid_credentials_handler
    render json: {
      code: Api::ResponseCodes::INVALID_CREDENTIALS,
      message: "Invalid email or password"
    },
    status: :unauthorized
  end

  def render_too_many_requests
    render json: {
      code: Api::ResponseCodes::TOO_MANY_REQUESTS,
      message: "Too many attempts, try again later"
    },
    status: :too_many_requests
  end

  def render_validation_error(errors)
    render json: {
      code: Api::ResponseCodes::VALIDATION_ERROR,
      message: "Validation failed",
      errors: errors
    },
    status: :bad_request
  end
end
