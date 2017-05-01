require 'kramdown'
require 'rouge'

class Resource
  include Udgoogle
  attr_reader :site, :uri, :path

  def initialize site, uri
    @site = site
    @uri = uri || '/'
    @path = sanitize_uri @uri
  end

  def sanitize_uri uri
    path = strip_query_string uri
    path += "index.html" if path[-1] == "/"
    begin
      detection = CharlockHolmes::EncodingDetector.detect(path)
      path = CharlockHolmes::Converter.convert path, detection[:encoding], 'UTF-8'
    rescue
    end
    URI.decode(path)
  end

  def contents
    expires_in = @site.creator && @site.creator.is_pro?  ? 5.seconds : 30.seconds
    begin
      Rails.cache.fetch("#{cache_key}/#{@uri}", expires_in: expires_in) do
        from_api
      end
    rescue Redis::TimeoutError => e
      Rails.logger.info e
      Rails.logger.info @site.name
      Rails.logger.info @uri
      from_api
    end
  end

  def from_api
    begin
      if @site.provider == 'google'
        @session = google_session(@site)
        @folders = google_folders(@session, build_query(@path), @site)
      end
      if @path == '/markdown.css'
        out = try_files [@path], @site, @site.dir(@folders), @folders, @session
        if out[:status] == 404
           out = {
             html: File.read(Rails.root.to_s + '/public/md.css').html_safe,
             status: 200
           }
        end
      else
        out = try_files [@path,'/404.html'], @site, @site.dir(@folders), @folders, @session
      end
      out[:content_type] = mime out[:status]
      out[:html] = markdown out[:html] if render_markdown?
    rescue Google::Apis::RateLimitError => e
      Rails.logger.info e
      Rails.logger.info "Site: #{@site.inspect} #{@uri}"
      out = {status: 500, html: 'Too many requests. Try again later.'}
    end
    out
  end

  def try_files uris, site, dir = nil, folders, session
    path = uris[0]
    if site.provider == 'dropbox'
      out = dropbox_content path
    elsif site.provider == 'google'
      out = google_content dir, folders, session
    end
    begin
      out.match //
    rescue ArgumentError => e # probably invalid byte sequence
      return {html: out, status: 200}
    end
    if out.match(/{\".tag\":/) || out.match('Error in call to API function')
      if out.match /path\/not_file/
        return {status: 301, location: path + '/'}
      end
      uris.shift
      if path.match(/\/index\.html$/)
        if directory_index_exists_in_any_parent_folder? path
          return {html: 'show folders', status: 200}
        end
      end
      if uris.length == 0
         return { html: File.read(Rails.public_path + 'load-404.html').html_safe, status: 404 }
      end
      return try_files uris, site, dir, folders
    end
    status = uris[0] == "/404.html" ? 404 : 200
    {html: out, status: status}
  end

  def directory_index_exists_in_any_parent_folder? path
    return false if @site.provider != "dropbox"
    url = 'https://api.dropboxapi.com/2/files/search'
    opts = {
      headers: {
        'Authorization' => "Bearer #{@site.identity.full_access_token || @site.identity.access_token}",
        "Content-Type" => "application/json"
      },
      body: {
        "path" => "#{@site.base_path}",
        "query" => "directory-index.html",
        "start" => 0,
        "max_results" => 100,
        "mode" => "filename"
      }.to_json
    }
    res = JSON.parse(HTTParty.post(url, opts).body)
    return false if res["matches"].nil?
    allowed = res["matches"].select do |match|
      found = match["metadata"]["path_lower"].gsub(@site.base_path,'').gsub("directory-index.html",'') # /jom/directory-index.html
      path.match(/^#{found}/)
    end
    allowed.any?
  end

  def access_token
    @site.db_path.present? ? @site.identity.full_access_token : @site.identity.access_token
  end

  def folder
    @site.db_path.present? ? @site.db_path : '/' + @site.name
  end

  def dropbox_content path
    document_root = self.site.document_root || ''
    file_path = folder + '/' + document_root + '/' + path
    file_path = file_path.gsub(/\/+/,'/')
    url = 'https://content.dropboxapi.com/2/files/download'
    opts = {
      headers: {
        'Authorization' => "Bearer #{access_token}",
        'Content-Type' => '',
        'Dropbox-API-Arg' => {
          path: file_path.gsub(/\?(.*)/,'')
        }.to_json
      }
    }
    res = HTTParty.post(url, opts)
    oat = res.body.html_safe
    begin
    oat = "Not found - Please Reauthenticate Dropbox" if oat.match("Invalid authorization value")
    rescue
    end
    oat
  end

  def get_temporary_link
    url = 'https://api.dropboxapi.com/2/files/get_temporary_link'
    document_root = self.site.document_root || ''
    file_path = folder + '/' + document_root + '/' + @path
    file_path = file_path.gsub(/\/+/,'/')
    token = self.site.identity.full_access_token || self.site.identity.access_token
    opts = {
      headers: self.class.db_headers(token),
      body: {
        path: file_path
      }.to_json
    }
    res = HTTParty.post(url, opts).body
    link = JSON.parse(res)["link"]
    p res if link.nil?
    link
  end

  def mime status
    extname = File.extname(strip_query_string(@path))[1..-1] || ""
    extname = extname.downcase
    mime_type = Rack::Mime.mime_type(extname)
    mime_type = 'text/html; charset=utf-8' if mime_type.nil?
    mime_type = 'text/html; charset=utf-8' if render_markdown?
    mime_type = 'text/html; charset=utf-8' if status == 404
    mime_type.to_s
  end

  def strip_query_string uri
    uri = uri.gsub(/\/+/,'/')
    begin
      stripped = URI.parse(uri).path
    rescue URI::InvalidURIError => e
      Rails.logger.info e
      stripped = uri
    end
    stripped
  end

  def render_markdown?
    can_render_markdown? && should_render_markdown?
  end

  def can_render_markdown?
    @site.creator.is_pro && @site.render_markdown
  end

  def should_render_markdown?
    @path.match(/\.(md|markdown)$/) && !@uri.match(/raw/)
  end

  def cache_key
    @site.updated_at.utc.to_s(:number) + @site.id.to_s
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

  def self.create_dropbox_folder(name, access_token)
    url = 'https://api.dropboxapi.com/2/files/create_folder'
    opts = {
      headers: db_headers(access_token),
      body: {
        path: name
      }.to_json
    }
    HTTParty.post(url, opts)
  end

  def self.create_dropbox_file(path, content, access_token)
    url = 'https://content.dropboxapi.com/2/files/upload'
    opts = {
        headers: {
        'Authorization' => "Bearer #{access_token}",
        'Content-Type' =>  'application/octet-stream',
        'Dropbox-API-Arg' => {
          path: path,
        }.to_json
      },
      body: content
    }
    HTTParty.post(url, opts)
  end

  def self.db_headers access_token
    {
      'Authorization' => "Bearer #{access_token}",
      'Content-Type' => 'application/json'
    }
  end

  def self.google_init identity, site, content
    return nil if Rails.env.test?
    sesh = GoogleDrive::Session.from_access_token(identity.access_token)
    begin
      drive = sesh.root_collection
      dir = drive.subcollections(q:'name = "UpDog" and trashed = false').first || drive.create_subcollection("UpDog")
      dir = dir.create_subcollection(site.name)
      site.update(google_id: dir.id)
      dir.upload_from_string(content, 'index.html', convert: false)
    rescue => e
      if e.to_s == "Unauthorized"
        identity.refresh_access_token
        self.google_init identity, site, content
      else
        raise e
      end
    end
  end

end
