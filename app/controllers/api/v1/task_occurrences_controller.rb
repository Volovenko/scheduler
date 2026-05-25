# frozen_string_literal: true

module Api
  module V1
    # Endpoints for managing individual occurrences of a recurring task.
    #
    # PATCH  /api/v1/tasks/:task_id/occurrences/:date
    #   Override status/title/description for a specific occurrence date.
    #
    # DELETE /api/v1/tasks/:task_id/occurrences/:date
    #   Cancel a specific occurrence (sets cancelled: true on the task_occurrence row).
    class TaskOccurrencesController < BaseController
      before_action :set_task
      before_action :parse_occurrence_date

      # PATCH /api/v1/tasks/:task_id/occurrences/:date
      #
      # Override status, title or description for a single occurrence date.
      # Creates a task_occurrence row on first interaction; updates it on subsequent calls.
      #
      # @param task_id [Integer] ID of the parent recurring task
      # @param date    [String]  occurrence date in ISO 8601 format (YYYY-MM-DD)
      # @option occurrence [String] :status    new status for this occurrence
      # @option occurrence [String] :title     override title (detaches from task template)
      # @option occurrence [String] :description override description
      # @return [JSON] serialized TaskOccurrence or error
      def update
        result = TaskOccurrences::UpsertService.new.call(@task, @date, occurrence_params)

        handle_result(result) do |occurrence|
          render json: occurrence, serializer: Api::V1::TaskOccurrenceSerializer
        end
      end

      # DELETE /api/v1/tasks/:task_id/occurrences/:date
      #
      # Cancel a single occurrence of a recurring task on the given date.
      # Sets cancelled: true on the task_occurrence row (does not delete the task).
      #
      # @param task_id [Integer] ID of the parent recurring task
      # @param date    [String]  occurrence date in ISO 8601 format (YYYY-MM-DD)
      # @return [void] 204 No Content on success, error JSON on failure
      def destroy
        result = TaskOccurrences::CancelService.new.call(@task, @date)

        handle_result(result) do
          head :no_content
        end
      end

      private

      def set_task
        @task = Task.find(params[:task_id])
        return if @task.recurring?

        render_error(
          code: "not_recurring",
          message: "Task is not recurring",
          status: :unprocessable_entity
        )
      end

      def parse_occurrence_date
        @date = Date.parse(params[:date])
      rescue ArgumentError, TypeError
        render_error(
          code: "invalid_date",
          message: "Invalid date format",
          details: { date: [ "must be a valid ISO 8601 date (YYYY-MM-DD)" ] },
          status: :unprocessable_entity
        )
      end

      # @return [Hash] whitelisted occurrence override attributes (empty if body absent)
      def occurrence_params
        return {} unless params.key?(:occurrence)

        params.require(:occurrence).permit(:status, :title, :description).to_h.symbolize_keys
      end
    end
  end
end
