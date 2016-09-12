class NewsController < ApplicationController
  def index
    f = Rails.root.join('news/_site/index.html')
    send_file f, :disposition => 'inline'
  end
  def show
    f = Rails.root.join('news/_site/'+ params[:path]+'/index.html')
    send_file f, :disposition => 'inline'
  end
  def css
    f = Rails.root.join('news/_site/css/main.css')
    send_file f, :disposition => 'inline'
  end
end
