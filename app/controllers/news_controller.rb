class NewsController < ApplicationController
  def index
    render file: 'news/_site/index.html'
  end
  def show
    file = params[:path] == "feed" ? "feed.xml" : params[:path] + '/index.html'
    @title = "Updog - " + params[:path].gsub('-',' ').titleize
    render file: 'news/_site/'+ file
  end
end
