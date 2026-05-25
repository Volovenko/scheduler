# frozen_string_literal: true

module Api
  module V1
    # CRUD endpoints for Tag resources.
    #
    # GET    /api/v1/tags          — full list (system + custom)
    # POST   /api/v1/tags          — create a custom tag
    # PATCH  /api/v1/tags/:id      — update a custom tag (system tags → 403)
    # DELETE /api/v1/tags/:id      — delete a custom tag (system tags → 403)
    class TagsController < BaseController
      before_action :set_tag, only: %i[update destroy]

      # GET /api/v1/tags
      def index
        tags = Tag.order(:name)
        render json: tags, each_serializer: Api::V1::TagSerializer
      end

      # POST /api/v1/tags
      def create
        result = Tags::CreateService.new.call(tag_params)

        handle_result(result) do |tag|
          render json: tag, serializer: Api::V1::TagSerializer, status: :created
        end
      end

      # PATCH /api/v1/tags/:id
      def update
        result = Tags::UpdateService.new.call(@tag, tag_params)

        handle_result(result) do |tag|
          render json: tag, serializer: Api::V1::TagSerializer
        end
      end

      # DELETE /api/v1/tags/:id
      def destroy
        result = Tags::DestroyService.new.call(@tag)

        handle_result(result) do
          head :no_content
        end
      end

      private

      def set_tag
        @tag = Tag.find(params[:id])
      end

      # @return [ActionController::Parameters] whitelisted tag attributes
      def tag_params
        params.require(:tag).permit(:name).to_h.symbolize_keys
      end
    end
  end
end
