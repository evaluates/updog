class NewsController < ApplicationController
  def index
    render file: Rails.root.join('news/_site/index.html')
  end
  def show
    render file: Rails.root.join('news/_site/'+ params[:path]+'/index.html')
  end
  def css
    f = Rails.root.join('news/_site/css/main.css')
    send_file f, :disposition => 'inline'
  end
end
