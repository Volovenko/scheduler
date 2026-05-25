require "rails_helper"
require "rswag/specs"

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("swagger").to_s

  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "Scheduler API",
        version: "v1",
        description: "Трекер рабочих задач для медицинского персонала"
      },
      paths: {},
      components: {
        schemas: {
          tag: {
            type: :object,
            properties: {
              id:     { type: :integer },
              name:   { type: :string },
              system: { type: :boolean }
            },
            required: %w[id name system]
          },
          tag_response: {
            type: :object,
            properties: {
              tag: { "$ref" => "#/components/schemas/tag" }
            }
          },
          recurrence_rule: {
            type: :object,
            nullable: true,
            properties: {
              id:             { type: :integer },
              rule_type:      { type: :string, enum: RecurrenceRule::RULE_TYPES },
              interval:       { type: :integer, nullable: true },
              day_of_month:   { type: :integer, nullable: true },
              specific_dates: { type: :array, items: { type: :string, format: :date }, nullable: true },
              even_odd:       { type: :string, nullable: true }
            },
            required: %w[id rule_type]
          },
          task: {
            type: :object,
            properties: {
              id:              { type: :integer },
              title:           { type: :string },
              description:     { type: :string, nullable: true },
              due_date:        { type: :string, format: :date, nullable: true },
              status:          { type: :string, enum: Task::STATUSES },
              recurring:       { type: :boolean },
              starts_on:       { type: :string, format: :date, nullable: true },
              ends_on:         { type: :string, format: :date, nullable: true },
              created_at:      { type: :string, format: :"date-time" },
              updated_at:      { type: :string, format: :"date-time" },
              tags:            { type: :array, items: { "$ref" => "#/components/schemas/tag" } },
              recurrence_rule: { "$ref" => "#/components/schemas/recurrence_rule" }
            },
            required: %w[id title status recurring created_at updated_at tags]
          },
          task_response: {
            type: :object,
            properties: {
              task: { "$ref" => "#/components/schemas/task" }
            }
          },
          task_occurrence: {
            type: :object,
            properties: {
              task_id:         { type: :integer },
              occurrence_date: { type: :string, format: :date },
              status:          { type: :string, enum: Task::STATUSES, nullable: true },
              title:           { type: :string, nullable: true },
              description:     { type: :string, nullable: true },
              cancelled:       { type: :boolean },
              created_at:      { type: :string, format: :"date-time" },
              updated_at:      { type: :string, format: :"date-time" }
            },
            required: %w[task_id occurrence_date cancelled created_at updated_at]
          },
          pagination_meta: {
            type: :object,
            properties: {
              current_page: { type: :integer },
              next_page:    { type: :integer, nullable: true },
              prev_page:    { type: :integer, nullable: true },
              total_pages:  { type: :integer },
              total_count:  { type: :integer }
            }
          },
          error_response: {
            type: :object,
            properties: {
              error: {
                type: :object,
                properties: {
                  code:    { type: :string },
                  message: { type: :string },
                  details: { type: :object }
                },
                required: %w[code message]
              }
            }
          }
        }
      },
      servers: [
        { url: "http://localhost:3000", description: "Local development" }
      ]
    }
  }

  config.openapi_format = :yaml
end
