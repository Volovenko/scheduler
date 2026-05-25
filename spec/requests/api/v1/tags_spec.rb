require "swagger_helper"

RSpec.describe "API::V1::Tags", type: :request do
  path "/api/v1/tags" do
    get "Returns all tags" do
      tags "Tags"
      produces "application/json"

      response "200", "list of tags" do
        schema type: :object,
               properties: {
                 tags: { type: :array, items: { "$ref" => "#/components/schemas/tag" } }
               }

        let!(:system_tag) { create(:tag, name: "отчетность", system: true) }
        let!(:custom_tag) { create(:tag) }

        run_test! do
          json = JSON.parse(response.body)
          expect(json["tags"].length).to be >= 2
        end
      end
    end

    post "Creates a custom tag" do
      tags "Tags"
      consumes "application/json"
      produces "application/json"
      parameter name: :tag, in: :body, schema: {
        type: :object,
        required: [ "tag" ],
        properties: {
          tag: {
            type: :object,
            required: [ "name" ],
            properties: { name: { type: :string, example: "срочное" } }
          }
        }
      }

      response "201", "tag created" do
        schema "$ref" => "#/components/schemas/tag_response"
        let(:tag) { { tag: { name: "срочное" } } }
        run_test! do
          json = JSON.parse(response.body)
          expect(json["tag"]["name"]).to eq("срочное")
          expect(json["tag"]["system"]).to be false
        end
      end

      response "422", "validation failed" do
        schema "$ref" => "#/components/schemas/error_response"
        let(:tag) { { tag: { name: "" } } }
        run_test!
      end
    end
  end

  path "/api/v1/tags/{id}" do
    parameter name: :id, in: :path, type: :integer, description: "Tag ID"

    patch "Updates a custom tag" do
      tags "Tags"
      consumes "application/json"
      produces "application/json"
      parameter name: :tag, in: :body, schema: {
        type: :object,
        properties: {
          tag: {
            type: :object,
            properties: { name: { type: :string } }
          }
        }
      }

      response "200", "tag updated" do
        schema "$ref" => "#/components/schemas/tag_response"
        let(:custom_tag) { create(:tag, name: "старое") }
        let(:id)  { custom_tag.id }
        let(:tag) { { tag: { name: "новое" } } }
        run_test! do
          expect(JSON.parse(response.body)["tag"]["name"]).to eq("новое")
        end
      end

      response "403", "system tag — modification forbidden" do
        schema "$ref" => "#/components/schemas/error_response"
        let(:system_tag) { create(:tag, name: "отчетность", system: true) }
        let(:id)  { system_tag.id }
        let(:tag) { { tag: { name: "новое" } } }
        run_test! do
          expect(response).to have_http_status(:forbidden)
        end
      end

      response "404", "tag not found" do
        schema "$ref" => "#/components/schemas/error_response"
        let(:id)  { 0 }
        let(:tag) { { tag: { name: "x" } } }
        run_test!
      end
    end

    delete "Deletes a custom tag" do
      tags "Tags"
      produces "application/json"

      response "204", "tag deleted" do
        let(:id) { create(:tag).id }
        run_test!
      end

      response "403", "system tag — deletion forbidden" do
        schema "$ref" => "#/components/schemas/error_response"
        let(:id) { create(:tag, name: "операции", system: true).id }
        run_test! do
          expect(response).to have_http_status(:forbidden)
        end
      end

      response "404", "tag not found" do
        schema "$ref" => "#/components/schemas/error_response"
        let(:id) { 0 }
        run_test!
      end
    end
  end
end
