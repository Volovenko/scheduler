# frozen_string_literal: true

module Api
  module V1
    # CRUD endpoints for Task resources.
    #
    # GET    /api/v1/tasks          — paginated list with optional filters (one-time + recurring)
    # POST   /api/v1/tasks          — create a task
    # GET    /api/v1/tasks/:id      — fetch a single task
    # PATCH  /api/v1/tasks/:id      — update a task
    # DELETE /api/v1/tasks/:id      — delete a task
    class TasksController < BaseController
      before_action :set_task, only: %i[show update destroy]

      # GET /api/v1/tasks
      #
      # Returns one-time tasks and recurring occurrences merged and sorted by due_date.
      # @param date_from [String] optional ISO-8601 date lower bound
      # @param date_to [String]   optional ISO-8601 date upper bound
      # @param status [Array<String>] optional status filter
      # @param tag_ids [Array<Integer>] optional tag filter (AND logic)
      def index
        result = TasksQuery.new.call(filter_params)
        pagy = Pagy.new(count: result[:total_count], page: result[:page], limit: result[:per_page])

        render json: result[:items],
               each_serializer: Api::V1::TaskSerializer,
               root: "tasks",
               meta: pagy_metadata(pagy)
      end

      # GET /api/v1/tasks/:id
      def show
        render json: @task, serializer: Api::V1::TaskSerializer
      end

      # POST /api/v1/tasks
      def create
        result = Tasks::CreateService.new.call(task_params)

        handle_result(result) do |task|
          render json: task, serializer: Api::V1::TaskSerializer, status: :created
        end
      end

      # PATCH /api/v1/tasks/:id
      def update
        result = Tasks::UpdateService.new.call(@task, task_params)

        handle_result(result) do |task|
          render json: task, serializer: Api::V1::TaskSerializer
        end
      end

      # DELETE /api/v1/tasks/:id
      def destroy
        result = Tasks::DestroyService.new.call(@task)

        handle_result(result) do
          head :no_content
        end
      end

      private

      def set_task
        @task = Task.find(params[:id])
      end

      # @return [ActionController::Parameters] whitelisted task attributes
      def task_params
        params.require(:task).permit(
          :title, :description, :due_date, :status,
          :recurring, :starts_on, :ends_on,
          recurrence_rule: [ :rule_type, :interval, :day_of_month, :even_odd,
                            { specific_dates: [] } ]
        ).to_h.deep_symbolize_keys
      end

      MAX_DATE_RANGE_DAYS = 90

      # @return [Hash] whitelisted filter params for TasksQuery with default date range
      def filter_params
        filters = params.permit(:date_from, :date_to, :page, status: [], tag_ids: []).to_h.symbolize_keys

        filters[:date_from] = Date.parse(filters[:date_from].to_s) rescue nil if filters[:date_from].present?
        filters[:date_to]   = Date.parse(filters[:date_to].to_s)   rescue nil if filters[:date_to].present?

        filters[:date_from] ||= Date.current
        filters[:date_to]   ||= filters[:date_from] + MAX_DATE_RANGE_DAYS.days

        if (filters[:date_to] - filters[:date_from]).to_i > MAX_DATE_RANGE_DAYS
          filters[:date_to] = filters[:date_from] + MAX_DATE_RANGE_DAYS.days
        end

        filters
      end
    end
  end
end
