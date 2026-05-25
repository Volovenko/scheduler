# frozen_string_literal: true

module Api
  module V1
    # Manages tag attachments on a specific task.
    #
    # POST   /api/v1/tasks/:task_id/tags     — attach a tag to the task
    # DELETE /api/v1/tasks/:task_id/tags/:id — detach a tag from the task
    class TaskTagsController < BaseController
      before_action :set_task
      before_action :set_tag, only: %i[destroy]

      # POST /api/v1/tasks/:task_id/tags
      #
      # @param tag_id [Integer] ID of the tag to attach
      def create
        tag    = Tag.find(params[:tag_id])
        result = TaskTags::AttachService.new.call(@task, tag)

        handle_result(result) do
          render json: @task.reload, serializer: Api::V1::TaskSerializer, status: :created
        end
      end

      # DELETE /api/v1/tasks/:task_id/tags/:id
      def destroy
        result = TaskTags::DetachService.new.call(@task, @tag)

        handle_result(result) do
          render json: @task.reload, serializer: Api::V1::TaskSerializer
        end
      end

      private

      def set_task
        @task = Task.find(params[:task_id])
      end

      def set_tag
        @tag = Tag.find(params[:id])
      end
    end
  end
end
