require 'kramdown'
require 'rouge'

class SitesController < ApplicationController
  layout "layouts/application"
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
    @site = Site.where("domain = ? OR subdomain = ?", request.host, request.host).first
    @site.clicks.create(data:{
      path: request.env["REQUEST_URI"],
      ip: request.env["REMOTE_ADDR"],
      referer: request.env["HTTP_REFERER"]
    })
    if !@site
     render :html => '<div class="wrapper">Not Found</div>'.html_safe, :layout => true
     return
    end
    uri = request.env['PATH_INFO']
    if uri == '/markdown.css'
      @content = try_files [uri], @site
      if @content[:html] == "Not Found"
	@content = {html: File.read(Rails.root.to_s + '/public/md.css').html_safe, status: 200}
      end
    else
      @content = try_files [uri, uri + '/index.html', uri + '/directory-index.html', '/404.html'], @site
      @content[:html] = markdown(@content[:html]) if render_markdown? @site, request
    end
    ct = mime(request, @site)
    respond_to do |format|
      format.all { render({:layout => false, :content_type => ct}.merge(@content)) }
    end
  end

  def mime request, site
    extname = File.extname(request.env['PATH_INFO'])[1..-1]
    mime_type = Mime::Type.lookup_by_extension(extname)
    mime_type.to_s unless mime_type.nil?
    mime_type = 'text/html; charset=utf-8' if mime_type.nil?
    mime_type = 'text/html; charset=utf-8' if render_markdown?(site, request)
    mime_type.to_s
  end

  def render_markdown? site, request
    can_render_markdown?(site) && should_render_markdown?(request)
  end

  def can_render_markdown? site
    site.creator.is_pro && site.render_markdown
  end

  def should_render_markdown? request
    uri = request.env['REQUEST_URI']
    uri.match(/\.(md|markdown)$/) && !uri.match(/raw/)
  end

  def markdown content
    md = Kramdown::Document.new(content.force_encoding('utf-8'),
      input: 'GFM',
      syntax_highlighter: 'rouge',
      syntax_highlighter_opts: {
	formatter: Rouge::Formatters::HTML
    }).to_html
    preamble = "<!doctype html><html><head><meta name='viewport' content='width=device-width'><meta charshet='utf-8'><link rel='stylesheet' type='text/css' href='/markdown.css'></head><body>"
    footer = "</body></html>"
    (preamble + md + footer).html_safe
  end

  def try_files uris, site
    out = site.content uris[0]
    if out.match(/{\".tag\":/) || out.match('Error in call to API function')
      uris.shift
      if uris.length == 0
	return { html: "Not Found", status: 404 }
      end
      return try_files uris, site
    end
    status = uris[0] == "/404.html" ? 404 : 200
    if uris[0].match "/directory-index.html"
      index = site.index(uris[0])
      @entries = index["entries"]
      @path = index["path"]
      html = render_to_string "sites/directory_index", layout: false
      return {html: html, status: status}
    end
    {html: out, status: status}
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
