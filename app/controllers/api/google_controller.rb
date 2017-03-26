module Api
  class GoogleController < ApplicationController
    include Udgoogle
    def files
      out = google_files params[:access_token], params[:site_id], params[:path]
      response.headers['APICalls'] = @calls.to_s
      render json: out
    end
  end
end
