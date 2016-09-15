class NewsController < ApplicationController
  def index
    render file: 'news/_site/index.html'
  end
  def show
    render file: 'news/_site/'+ params[:path]+'/index.html'
  end
end
