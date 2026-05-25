require "swagger_helper"

RSpec.describe "API::V1::TaskOccurrences", type: :request do
  let(:task) do
    t = create(:task, :recurring, starts_on: Date.new(2026, 6, 1), ends_on: Date.new(2026, 6, 30))
    create(:recurrence_rule, :daily, task: t, interval: 1)
    t
  end
  let(:date) { "2026-06-10" }

  path "/api/v1/tasks/{task_id}/occurrences/{date}" do
    parameter name: :task_id, in: :path, type: :integer, required: true,
              description: "ID of the parent task"
    parameter name: :date, in: :path, type: :string, format: :date, required: true,
              description: "Occurrence date (YYYY-MM-DD)"

    patch "Override a single occurrence" do
      tags "Task Occurrences"
      consumes "application/json"
      produces "application/json"
      parameter name: :occurrence, in: :body, required: false, schema: {
        type: :object,
        properties: {
          occurrence: {
            type: :object,
            properties: {
              status:      { type: :string, enum: Task::STATUSES },
              title:       { type: :string },
              description: { type: :string }
            }
          }
        }
      }

      response "200", "occurrence updated" do
        schema type: :object,
               properties: {
                 task_occurrence: { "$ref" => "#/components/schemas/task_occurrence" }
               }

        let(:task_id)    { task.id }
        let(:occurrence) { { occurrence: { status: "completed" } } }

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json["task_occurrence"]["status"]).to eq("completed")
          expect(json["task_occurrence"]["cancelled"]).to be false
        end
      end

      response "200", "occurrence updated with no body" do
        schema type: :object,
               properties: {
                 task_occurrence: { "$ref" => "#/components/schemas/task_occurrence" }
               }

        let(:task_id)    { task.id }
        let(:occurrence) { nil }

        run_test! do
          expect(response).to have_http_status(:ok)
        end
      end

      response "404", "task not found" do
        schema "$ref" => "#/components/schemas/error_response"

        let(:task_id)    { 0 }
        let(:occurrence) { { occurrence: { status: "completed" } } }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end

      response "422", "invalid date format" do
        schema "$ref" => "#/components/schemas/error_response"

        let(:task_id) { task.id }
        let(:date)    { "not-a-date" }
        let(:occurrence) { {} }

        run_test! do
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end

    delete "Cancel a single occurrence" do
      tags "Task Occurrences"
      produces "application/json"

      response "204", "occurrence cancelled" do
        let(:task_id) { task.id }

        run_test! do
          expect(response).to have_http_status(:no_content)
          expect(TaskOccurrence.find_by(task_id: task.id, occurrence_date: date)).to be_cancelled
        end
      end

      response "404", "task not found" do
        schema "$ref" => "#/components/schemas/error_response"

        let(:task_id) { 0 }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
