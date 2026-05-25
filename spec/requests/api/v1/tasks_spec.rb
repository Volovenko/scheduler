require "swagger_helper"

RSpec.describe "API::V1::Tasks", type: :request do
  path "/api/v1/tasks" do
    get "Returns paginated list of tasks" do
      tags "Tasks"
      produces "application/json"
      parameter name: :date_from, in: :query, type: :string, format: :date, required: false,
                description: "Filter tasks with due_date >= date_from (ISO 8601)"
      parameter name: :date_to,   in: :query, type: :string, format: :date, required: false,
                description: "Filter tasks with due_date <= date_to (ISO 8601)"
      parameter name: "status[]",  in: :query, type: :array, items: { type: :string },
                required: false, description: "Filter by status values"
      parameter name: "tag_ids[]", in: :query, type: :array, items: { type: :integer },
                required: false, description: "Filter by tag IDs (AND logic — task must have all)"

      response "200", "tasks list" do
        schema type: :object,
               properties: {
                 tasks: {
                   type: :array,
                   items: { "$ref" => "#/components/schemas/task" }
                 },
                 meta: { "$ref" => "#/components/schemas/pagination_meta" }
               }

        let!(:task1) { create(:task) }
        let!(:task2) { create(:task, :in_progress) }
        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json["tasks"].length).to eq(2)
          expect(json).to have_key("meta")
        end
      end

      response "200", "includes recurring occurrences" do
        schema type: :object,
               properties: {
                 tasks: { type: :array, items: { "$ref" => "#/components/schemas/task" } },
                 meta:  { "$ref" => "#/components/schemas/pagination_meta" }
               }

        let!(:recurring_task) do
          t = create(:task, :recurring, starts_on: Date.new(2026, 6, 1), ends_on: Date.new(2026, 6, 3))
          create(:recurrence_rule, :daily, task: t, interval: 1)
          t
        end

        run_test! do
          json = JSON.parse(response.body)
          # 3 occurrences: Jun 1, 2, 3
          recurring_items = json["tasks"].select { |t| t["recurring"] == true }
          expect(recurring_items.length).to eq(3)
        end
      end

      response "200", "filtered by status" do
        schema type: :object,
               properties: {
                 tasks: { type: :array, items: { "$ref" => "#/components/schemas/task" } }
               }

        let!(:pending_task)   { create(:task, status: "pending") }
        let!(:completed_task) { create(:task, :completed) }
        let(:"status[]")      { [ "pending" ] }
        run_test! do
          json = JSON.parse(response.body)
          expect(json["tasks"].all? { |t| t["status"] == "pending" }).to be true
        end
      end
    end

    post "Creates a task" do
      tags "Tasks"
      consumes "application/json"
      produces "application/json"
      parameter name: :task, in: :body, schema: {
        type: :object,
        properties: {
          task: {
            type: :object,
            required: %w[title],
            properties: {
              title:       { type: :string, example: "Провести операцию" },
              description: { type: :string },
              due_date:    { type: :string, format: :date },
              status:      { type: :string, enum: Task::STATUSES },
              recurring:   { type: :boolean },
              starts_on:   { type: :string, format: :date },
              ends_on:     { type: :string, format: :date },
              recurrence_rule: {
                type: :object,
                properties: {
                  rule_type:      { type: :string, enum: RecurrenceRule::RULE_TYPES },
                  interval:       { type: :integer },
                  day_of_month:   { type: :integer },
                  specific_dates: { type: :array, items: { type: :string, format: :date } },
                  even_odd:       { type: :string, enum: %w[even odd] }
                }
              }
            }
          }
        }
      }

      response "201", "task created" do
        schema "$ref" => "#/components/schemas/task_response"
        let(:task) { { task: { title: "Обзвонить пациентов", due_date: Date.current + 1, recurring: false } } }
        run_test! do
          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)
          expect(json["task"]["title"]).to eq("Обзвонить пациентов")
        end
      end

      response "201", "recurring task created with recurrence_rule" do
        schema "$ref" => "#/components/schemas/task_response"
        let(:task) do
          {
            task: {
              title:     "Утренний обход",
              recurring: true,
              starts_on: "2026-06-01",
              ends_on:   "2026-06-30",
              recurrence_rule: { rule_type: "daily", interval: 1 }
            }
          }
        end
        run_test! do
          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)
          expect(json["task"]["recurring"]).to be true
          expect(json["task"]["recurrence_rule"]["rule_type"]).to eq("daily")
        end
      end

      response "422", "validation failed" do
        schema "$ref" => "#/components/schemas/error_response"
        let(:task) { { task: { title: "", recurring: false } } }
        run_test! do
          expect(response).to have_http_status(:unprocessable_content)
          json = JSON.parse(response.body)
          expect(json["error"]["code"]).to eq("validation_error")
        end
      end
    end
  end

  path "/api/v1/tasks/{id}" do
    parameter name: :id, in: :path, type: :integer, description: "Task ID"

    get "Returns a task" do
      tags "Tasks"
      produces "application/json"

      response "200", "task found" do
        schema "$ref" => "#/components/schemas/task_response"
        let(:id) { create(:task).id }
        run_test! do
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)).to have_key("task")
        end
      end

      response "404", "task not found" do
        schema "$ref" => "#/components/schemas/error_response"
        let(:id) { 0 }
        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    patch "Updates a task" do
      tags "Tasks"
      consumes "application/json"
      produces "application/json"
      parameter name: :task, in: :body, schema: {
        type: :object,
        properties: {
          task: {
            type: :object,
            properties: {
              title:  { type: :string },
              status: { type: :string, enum: Task::STATUSES }
            }
          }
        }
      }

      response "200", "task updated" do
        schema "$ref" => "#/components/schemas/task_response"
        let(:existing_task) { create(:task) }
        let(:id)   { existing_task.id }
        let(:task) { { task: { status: "in_progress" } } }
        run_test! do
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)["task"]["status"]).to eq("in_progress")
        end
      end

      response "422", "validation failed" do
        schema "$ref" => "#/components/schemas/error_response"
        let(:existing_task) { create(:task) }
        let(:id)   { existing_task.id }
        let(:task) { { task: { status: "bad_value" } } }
        run_test!
      end

      response "404", "task not found" do
        schema "$ref" => "#/components/schemas/error_response"
        let(:id)   { 0 }
        let(:task) { { task: { title: "x" } } }
        run_test!
      end
    end

    delete "Deletes a task" do
      tags "Tasks"
      produces "application/json"

      response "204", "task deleted" do
        let(:id) { create(:task).id }
        run_test! do
          expect(response).to have_http_status(:no_content)
        end
      end

      response "404", "task not found" do
        schema "$ref" => "#/components/schemas/error_response"
        let(:id) { 0 }
        run_test!
      end
    end
  end
end
