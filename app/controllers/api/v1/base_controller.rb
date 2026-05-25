# frozen_string_literal: true

module Api
  module V1
    # Base controller for all API v1 controllers.
    #
    # Disables CSRF protection (API-only), includes unified error handling,
    # and sets JSON as the default response format.
    class BaseController < ActionController::API
      include ApiErrorHandler
      include Pagy::Backend

      private

      # Renders a Dry::Monads::Result returned from a service.
      #
      # On Success — yields to the block with the unwrapped value.
      # On Failure — renders a JSON error using the failure hash.
      #
      # @param result [Dry::Monads::Result] the monad to handle
      # @yieldparam value [Object] the unwrapped success value
      def handle_result(result)
        case result
        in Dry::Monads::Result::Success[ value ]
          yield value
        in Dry::Monads::Result::Failure[ { code:, errors: } ]
          render_error(
            code: code.to_s,
            message: human_message_for(code),
            details: errors,
            status: http_status_for(code)
          )
        end
      end

      def human_message_for(code)
        case code.to_sym
        when :validation_error     then "Validation failed"
        when :unprocessable_entity then "Unable to process request"
        when :not_found            then "Record not found"
        when :forbidden            then "Action not permitted"
        else "An error occurred"
        end
      end

      def http_status_for(code)
        case code.to_sym
        when :validation_error, :unprocessable_entity then :unprocessable_entity
        when :not_found                               then :not_found
        when :forbidden                               then :forbidden
        else :internal_server_error
        end
      end
    end
  end
end
