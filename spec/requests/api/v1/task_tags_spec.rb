require "swagger_helper"

RSpec.describe "API::V1::TaskTags", type: :request do
  let(:task) { create(:task) }
  let(:tag)  { create(:tag) }

  path "/api/v1/tasks/{task_id}/tags" do
    parameter name: :task_id, in: :path, type: :integer, description: "Task ID"

    post "Attaches a tag to the task" do
      tags "Task Tags"
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, schema: {
        type: :object,
        required: ["tag_id"],
        properties: { tag_id: { type: :integer, description: "ID of the tag to attach" } }
      }

      response "201", "tag attached — returns updated task" do
        schema "$ref" => "#/components/schemas/task_response"
        let(:task_id) { task.id }
        let(:body)    { { tag_id: tag.id } }
        run_test! do
          json = JSON.parse(response.body)
          tag_ids = json["task"]["tags"].map { |t| t["id"] }
          expect(tag_ids).to include(tag.id)
        end
      end

      response "404", "task or tag not found" do
        schema "$ref" => "#/components/schemas/error_response"
        let(:task_id) { 0 }
        let(:body)    { { tag_id: tag.id } }
        run_test!
      end
    end
  end

  path "/api/v1/tasks/{task_id}/tags/{id}" do
    parameter name: :task_id, in: :path, type: :integer, description: "Task ID"
    parameter name: :id,      in: :path, type: :integer, description: "Tag ID"

    delete "Detaches a tag from the task" do
      tags "Task Tags"
      produces "application/json"

      response "200", "tag detached — returns updated task" do
        schema "$ref" => "#/components/schemas/task_response"
        let(:task_id) { task.id }
        let(:id)      { tag.id }
        before        { task.tags << tag }
        run_test! do
          json = JSON.parse(response.body)
          expect(json["task"]["tags"].map { |t| t["id"] }).not_to include(tag.id)
        end
      end

      response "404", "tag not attached to task" do
        schema "$ref" => "#/components/schemas/error_response"
        let(:task_id) { task.id }
        let(:id)      { tag.id }
        run_test!
      end
    end
  end
end
