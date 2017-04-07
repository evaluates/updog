require 'digest'

class SitesController < ApplicationController
  layout "layouts/application"
  protect_from_forgery except: [:load, :passcode_verify, :send_contact]
  before_filter :authenticate, only: [:load]

  def send_contact
    if request.env["REQUEST_PATH"].match(/\.php$/)
      return render nothing: true
    end
    @site = Site.where("domain = ? OR subdomain = ?", request.host, request.host).first
    begin
      unless request.env['HTTP_REFERER'].match(@site.domain) || request.env['HTTP_REFERER'].match(@site.subdomain)
	       return render nothing: true
      end
      return redirect_to :back unless @site.creator.is_pro
      if @site.contact_email.present?
        email = @site.contact_email
      else
        email = @site.creator.email
      end
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

  def index
    @sites = current_user.sites if current_user
    @count = File.read(Rails.root.join("tmp/request-count.txt"))
  end
  def edit
    return redirect_to root_path unless current_user
    @site = current_user.sites.find(params[:id])
    @providers = current_user.identities.map(&:provider)
    @identity = current_user.identities.find_by(provider: 'dropbox')
    session[:back_to] = request.url
  end
  def new
    session[:back_to] = request.url
    return redirect_to root_path unless current_user
    @sites = current_user.sites
    @providers = current_user.identities.map(&:provider)
    unless current_user.is_pro? || @sites.length == 0
      redirect_to root_path
    end
    provider = (@providers.include? 'dropbox') ? 'dropbox' : 'google'
    @site = Site.new(provider:provider)
    @identity = current_user.identities.find_by(provider: provider)
  end

  def show
    begin
      @site = current_user.sites.find(params[:id])
    rescue
      return render :html => '<div class="wrapper">Not Found</div>'.html_safe, :layout => true, status: 404, content_type: 'text/html'
    end
    @identity = current_user.identities.find_by(provider: @site.provider)
    @sites = current_user && current_user.sites || []
  end
  def destroy
    @site = current_user.sites.find(params[:id])
    @site.destroy
    redirect_to sites_path, :notice => "Deleted. #{undo_link}?"
  end

  def authenticate
    @site = Site.where("domain = ? OR subdomain = ?", request.host, request.host).first
    return nil unless @site
    if request.env["REQUEST_PATH"] == @site.passcode_logo_path && @site.passcode_logo_path.present?
      return true
    end
    if @site.username.present?
      authenticate_or_request_with_http_basic do |name, password|
        name == @site.username && Digest::SHA2.hexdigest(password) == @site.encrypted_passcode
      end
    elsif @site.encrypted_passcode != "" && @site.encrypted_passcode != session["passcode_for_#{@site.id}"]
      if session["passcode_for_#{@site.id}"]
        flash.now[:alert] = "Passcode incorrect"
      end
      return render 'enter_passcode', layout: false
    end
  end

  def load
    @site = Site.where("domain = ? OR subdomain = ?", request.host, request.host).first
    if !@site
     render :html => '<div class="wrapper">Not Found</div>'.html_safe, :layout => true
     return
    end
    if request.env["HTTP_REFERER"] && request.env["HTTP_REFERER"].match(/www.hdvn1.com/)
      respond_to do |format|
        format.all { render({layout: false}.merge(html: 'hot linking not allowed')) }
      end
      return
    end
    @site.clicks.create(data:{
      path: request.env["REQUEST_URI"],
      ip: request.env["REMOTE_ADDR"],
      referer: request.env["HTTP_REFERER"]
    })
    uri = request.env['REQUEST_URI'] || request.env['PATH_INFO']
    @resource = Resource.new(@site, uri)
    if @site.provider == 'dropbox'
      if (uri && uri.match(/(\.zip|\.epub)/)) || params[:dl] == '1'
        return redirect_to @resource.get_temporary_link
      end
    end
    begin
      @content = @site.content( uri )
      if @content[:status] == 301
        location = Rails.env.test? ? uri + 'g' : @content[:location]
        #TODO fix capybara redirect issue
        return redirect_to location
      end
    rescue => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n")
      if @site.provider == 'dropbox'
        return redirect_to @resource.get_temporary_link
      end
      return raise e
    end
    if @content[:html] == 'show folders'
      @path = URI.decode(uri)
      @entries = dropbox_files(@site.base_path + uri,@site.identity.full_access_token || @site.identity.access_token)
      return render 'directory_index', layout: false
    end
    begin
      @content[:html] = @content[:html].gsub("</body>","#{injectee(@site)}</body>").html_safe if @site.inject? && @content[:status] == 200
    rescue ArgumentError => e # probably invalid byte sequence
      Rails.logger.info "Invalid byte sequence error, not injecting"
    end
    respond_to do |format|
      format.all { render({layout: false}.merge(@content)) }
    end
  end

  def injectee site
    render_to_string(
      template: "sites/injectee",
      layout: false,
      locals: {
        site: site
      },
      formats: [:html]
    )
  end

  def create
    @site = current_user.sites.create site_params
    @identity = current_user.identities.find_by(provider: @site.provider)
    @providers = current_user.identities.map(&:provider)
    if @site.save
      if params[:site][:db_path].present? # probably using some existing code
        return redirect_to @site
      end
      path = "/" + @site.name
      content = render_to_string(:template => "sites/welcome", :layout => false, locals: {
          site: @site
      })
      if params[:site][:provider] == "dropbox"
        Resource.create_dropbox_folder(path, @identity.access_token)
        Resource.create_dropbox_file(path + "/index.html", content, @identity.access_token)
      elsif params[:site][:provider] == "google"
        Resource.google_init @identity, @site, content
      end
      redirect_to @site
    else

      render :new
    end
  end

  def update
    @site = current_user.sites.find(params[:id])
    @providers = current_user.identities.map(&:provider)
    @identity = current_user.identities.find_by(provider:@site.provider)
    if @site.update site_params
      redirect_to @site
    else
      render :edit
    end
  end

  def passcode_verify
    @site = Site.where("domain = ? OR subdomain = ?", request.host, request.host).first
    passcode = params[:passcode]
    session["passcode_for_#{@site.id}"] = Digest::SHA2.hexdigest(passcode)
    redirect_to :back
  end

  def password # for deletin
    @site = current_user.sites.find(params[:site_id])
    @site.update(encrypted_passcode: nil, username: nil)
    redirect_to :back
  end

  private

  def site_params
    params.require(:site).permit(:passcode_text, :passcode_logo_path, :contact_email, :name, :domain, :document_root, :render_markdown, :db_path, :passcode, :username, :provider)
  end

  def undo_link
    view_context.link_to("undo", revert_version_path(@site.versions.last), :method => :post)
  end

end
