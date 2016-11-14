class SitesController < ApplicationController
  protect_from_forgery except: :load
  def index
    @sites = Site.where( uid: session[:user_id] )
  end
  def edit
    @site = Site.find_by( uid: session[:user_id], id: params[:id] )
    session[:back_to] = request.url
  end
  def new
    session[:back_to] = request.url
    @sites = Site.where( uid: session[:user_id] )
    return redirect_to root_path if !current_user
    unless current_user.is_pro? || @sites.length == 0
      redirect_to root_path
    end
    @site = Site.new
  end
  def show
    @site = Site.find_by( uid: session[:user_id], id: params[:id] )
    unless @site
      return render :html => '<div class="wrapper">Not Found</div>'.html_safe, :layout => true, status: 404
    end
    @sites = current_user && current_user.sites || []
  end
  def destroy
    @site = Site.find_by( uid: session[:user_id], id: params[:id] )
    @site.destroy
    redirect_to sites_path, :notice => "Deleted. #{undo_link}?"
  end
  def load
    request.env["referrer"] = request.referer
    @site = Site.where("domain = ? OR subdomain = ?", request.host, request.host).first
    if !@site
     render :html => '<div class="wrapper">Not Found</div>'.html_safe, :layout => true
     return
    end
    begin
      @content = @site.content request.env
      raise @content if @content["error"]
    rescue Exception => err
      @content = err
      if err.to_s.match("not_file")
	   return redirect_to request.env['REQUEST_URI'] + "/"
      end
      if err.to_s.match("not_found")
      	if request.env['PATH_INFO'] == '/markdown.css'
      	  @content = File.read(Rails.root.to_s + '/public/md.css').html_safe
      	else
      	  request.env['PATH_INFO'] = "/404.html"
          @content = @site.content request.env
          @content = "Not found" if @content.match(/{\".tag\": \"not_found\"}/)
          logger.error err.message
      	end
      end
    end
    extname = File.extname(request.env['PATH_INFO'])[1..-1]
    mime_type = Mime::Type.lookup_by_extension(extname)
    content_type = mime_type.to_s unless mime_type.nil?
    content_type = mime_type.nil? ? 'text/html; charset=utf-8' : mime_type.to_s
    content_type = "text/html; charset=utf-8" if extname == "md" && !params.key?(:raw) && @site.creator.is_pro? && @site.render_markdown
    respond_to do |format|
      format.all { render :html => @content, :layout => false, :content_type => content_type }
    end
  end
  def create
    @site = Site.new site_params.merge( uid: session[:user_id] )
    if @site.save
      if params[:db_path] == ""
        return redirect_to @site
      end
      begin
      	url = 'https://api.dropboxapi.com/2/files/create_folder'
      	opts = {
        	headers: headers,
      	  body: {
      	    path: @site.name
      	  }.to_json
      	}
      	HTTParty.post(url, opts)
      	url = 'https://content.dropboxapi.com/2/files/upload'
      	opts = {
        	  headers: {
      	    'Authorization' => "Bearer #{session["access_token"]}",
      	    'Content-Type' =>  'application/octet-stream',
      	    'Dropbox-API-Arg' => {
      	      path: '/' + @site.name + '/index.html',
      	    }.to_json
      	  },
      	  body: File.read(Rails.public_path + 'welcome/index.html')
      	}
      	HTTParty.post(url, opts)
      rescue => e
	       p e
      end
      redirect_to @site
    else
      render :new
    end
  end
  def update
    @site = Site.find_by( uid: session[:user_id], id: params[:id] )
    if @site.update site_params.merge( uid: session[:user_id] )
      redirect_to @site
    else
      render :edit
    end
  end

  def send_contact
    @site = Site.where("domain = ? OR subdomain = ?", request.host, request.host).first
    begin
      unless request.env['HTTP_REFERER'].match(@site.domain) || request.env['HTTP_REFERER'].match(@site.subdomain)
	return render nothing: true
      end
      return redirect_to :back unless @site.creator.is_pro
      email = @site.creator.email
      @input = params.except(:action, :controller, :redirect)
      ContactMailer.user_mailer(email, @site.link, @input).deliver_now!
      @site.contacts.create!(params: @input)
      if params[:redirect]
	redirect_to params[:redirect]
      else
	redirect_to :back
      end
    rescue
      render nothing: true
    end
  end
  def folders
    path = params[:path] || ""
    at = params[:access_token] || ""
    if at.blank?
      return render json: {
        error: "missing access token"
      }
    end
    url = 'https://api.dropboxapi.com/2/files/list_folder'
    opts = {
      headers: {
        'Authorization' => 'Bearer ' + at,
	'Content-Type' => 'application/json'
      },
      body: {
        path: path,
      }.to_json
    }
    res = HTTParty.post(url, opts)
    if res.body.match("Error")
      return render json: {error: res}
    end
    entries = JSON.parse(res.body)["entries"] || []
    folders = entries.select{|entry|
      entry[".tag"] == "folder"
    }.sort_by{|folder| folder["name"] }
    response.headers['Has_more'] = res["has_more"].to_s
    render json: folders, content_type: 'application/json'
  end

  private
  def headers
    {
      'Authorization' => "Bearer #{session["access_token"]}",
      'Content-Type' => 'application/json'
    }
  end
  def site_params
    params.require(:site).permit(:name, :domain, :document_root, :render_markdown, :db_path)
  end
  def undo_link
    view_context.link_to("undo", revert_version_path(@site.versions.last), :method => :post)
  end
end
