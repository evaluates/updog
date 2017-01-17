module Api
  class GoogleController < ApplicationController
    include Udgoogle
    def files
      identity = Identity.find_by(access_token: params[:access_token])
      @site = identity.user.sites.find(params[:site_id])
      s = GoogleDrive::Session.from_access_token(identity.access_token)
      path = params[:path] || "/#{@site.name}"
      @calls = 0
      folders = google_folders(s, build_query(path), @site)
      out = json(collection_from_path(s, path, folders).files, path)
      response.headers['APICalls'] = @calls.to_s
      render json: out
    end
  end
end
