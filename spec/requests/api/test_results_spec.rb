require 'rails_helper'

RSpec.describe "Api::TestResults", type: :request do
  describe "GET /create" do
    it "returns http success" do
      get "/api/test_results/create"
      expect(response).to have_http_status(:success)
    end
  end

end
