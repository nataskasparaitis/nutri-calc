# frozen_string_literal: true

class Session < ApplicationRecord
  USER_AGENT_MAX_LENGTH = 255

  belongs_to :user

  normalizes :user_agent, with: ->(user_agent) { user_agent.first(USER_AGENT_MAX_LENGTH) }
end
