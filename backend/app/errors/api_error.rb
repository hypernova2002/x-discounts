# frozen_string_literal: true

# Every error response in the API — auth failures, missing records, validation
# failures — is one of these, rendered from ApplicationController's single
# rescue_from. `details` is an array of {field, message} for field-specific
# problems (validation); leave it empty for errors that aren't field-specific
# (not_found, forbidden, etc).
class ApiError < StandardError
  attr_reader :code, :details

  def initialize(code, message: nil, details: [])
    @code = code
    @details = details
    config = ErrorCodes::REGISTRY.fetch(code) { raise ArgumentError, "unknown error code: #{code}" }
    super(message || config[:default_message])
  end

  def status
    ErrorCodes::REGISTRY.fetch(code)[:status]
  end

  def to_response
    { error: { code: code.to_s, message: message, details: details } }
  end
end
