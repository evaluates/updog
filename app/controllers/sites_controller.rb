class SitesController < ApplicationController
  protect_from_forgery except: :load
  def index
    @sites = Site.where( uid: session[:user_id] )
  end
  def edit
    @site = Site.find_by( uid: session[:user_id], id: params[:id] )
  end
  def new
    @sites = Site.where( uid: session[:user_id] )
    return redirect_to root_path if !current_user
    unless current_user.is_pro? || @sites.length == 0
      redirect_to root_path
    end
    @site = Site.new
  end
  def show
    @site = Site.find_by( uid: session[:user_id], id: params[:id] )
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
      @content = @site.content get_client( @site.creator.access_token ), request.env
    rescue Exception => err
      @content = err
      if err.to_s == "Path is a directory"
	return redirect_to request.env['REQUEST_URI'] + "/"
      end
      if err.to_s == "File not found" || err.to_s == "File has been deleted"
	if request.env['PATH_INFO'] == '/markdown.css'
	  @content = File.read(Rails.root.to_s + '/public/md.css').html_safe
	else
	  request.env['PATH_INFO'] = "/404.html"
	  begin
	    @content = @site.content get_client( @site.creator.access_token ), request.env
	  rescue Exception => err
	    @content = err
	  end
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
    @db = get_client @site.creator.access_token
    if @site.save
      begin
        @db.file_create_folder( @site.name )
        @db.put_file('/' + @site.name + '/index.html', open(Rails.public_path + 'welcome/index.html'))
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

  def add_to db, path
    db.put_file('/' + @site.name + '/index.html', open(path) )
  end

  private
  def site_params
    params.require(:site).permit(:name, :domain, :document_root, :render_markdown)
  end
  def undo_link
    view_context.link_to("undo", revert_version_path(@site.versions.last), :method => :post)
  end
end
