# frozen_string_literal: true

# Concern that provides a unified JSON error format and rescues common exceptions.
#
# All API controllers should include this module.
# Error shape: { error: { code: String, message: String, details: Hash } }
module ApiErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActionController::ParameterMissing, with: :render_bad_request
  end

  # Renders a standardised error response.
  #
  # @param code [String, Symbol] machine-readable error code
  # @param message [String] human-readable description
  # @param details [Hash] optional field-level error details
  # @param status [Integer, Symbol] HTTP status code
  def render_error(code:, message:, details: {}, status: :unprocessable_entity)
    render json: { error: { code: code, message: message, details: details } }, status: status
  end

  private

  def render_not_found
    render_error(code: "not_found", message: "Record not found", status: :not_found)
  end

  def render_bad_request(exception)
    render_error(code: "bad_request", message: exception.message, status: :bad_request)
  end
end
