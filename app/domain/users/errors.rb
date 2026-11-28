# frozen_string_literal: true

module Users::Errors
  class InvalidCredentials < StandardError; end
  class AccessDenied < StandardError; end
end
