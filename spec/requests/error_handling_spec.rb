require 'rails_helper'

RSpec.describe 'Error Handling', type: :request do
  describe 'error responses' do
    before do
      Rails.application.routes.draw do
        get 'test/not_found', to: 'test_errors#not_found'
        get 'test/parameter_missing', to: 'test_errors#parameter_missing'
        get 'test/standard_error', to: 'test_errors#standard_error'
      end
    end

    after do
      Rails.application.reload_routes!
    end

    it 'handles record not found errors' do
      get '/test/not_found'

      expect(response).to have_http_status(:not_found)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('Not Found')
      expect(json_response['message']).to eq('Record not found')
      expect(json_response['timestamp']).to be_present
    end

    it 'handles parameter missing errors' do
      get '/test/parameter_missing'

      expect(response).to have_http_status(:bad_request)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('Bad Request')
      expect(json_response['message']).to include('required_param')
      expect(json_response['timestamp']).to be_present
    end

    it 'handles standard errors' do
      get '/test/standard_error'

      expect(response).to have_http_status(:internal_server_error)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('Internal Server Error')
      expect(json_response['message']).to eq('Something went wrong')
      expect(json_response['timestamp']).to be_present
    end

    it 'includes backtrace in development environment' do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development'))

      get '/test/standard_error'

      json_response = JSON.parse(response.body)
      expect(json_response['backtrace']).to be_present
      expect(json_response['backtrace']).to be_an(Array)
    end
  end
end
