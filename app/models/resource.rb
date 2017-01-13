require 'kramdown'
require 'rouge'

class Resource

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
    begin
      puts "__: site updated at #{@site.updated_at}"
      if (Time.now - @site.updated_at) > 5
        puts "cache is stale, updating async"
        ContentWorker.perform_async(@site.id, @uri, cache_key)
      end
      puts "__: should be in #{cache_key}/#{@uri}"
      Rails.cache.fetch("#{cache_key}/#{@uri}") do
        puts "__: not in cache #{cache_key}/#{@uri}"
        from_api
      end
    rescue => e
      Rails.logger.info "contents error: site: #{@site.link}#{@uri}"
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n")
      {html: "An unknown error occurred. Please try again later.", status: 500}
    end
  end

  def from_api
    begin
      if @site.provider == 'google'
          @folders = google_folders
      end
      if @path == '/markdown.css'
        out = try_files [@path], @site, @site.dir, @folders
        if out[:status] == 404
           out = {
             html: File.read(Rails.root.to_s + '/public/md.css').html_safe,
             status: 200
           }
        end
      else
        out = try_files [@path,@path+'/index.html','/404.html'], @site, @site.dir, @folders
      end
      out[:content_type] = mime out[:status]
      out[:html] = markdown out[:html] if render_markdown?
    rescue Google::Apis::RateLimitError => e
      Rails.logger.info e
      Rails.logger.info "URI: #{@uri}"
      Rails.logger.info "Site: #{@site.inspect}"
      out = {status: 500, html: 'Too many requests. Try again later.'}
    end
    out
  end

  def try_files uris, site, dir = nil, folders
    path = uris[0]
    if site.provider == 'dropbox'
      out = dropbox_content
    elsif site.provider == 'google'
      out = google_content dir, folders
    end
    if out.match(/{\".tag\":/) || out.match('Error in call to API function')
      uris.shift
      if uris.length == 0
         return { html: File.read(Rails.public_path + 'load-404.html').html_safe, status: 404 }
      end
      return try_files uris, site, dir, folders
    end
    status = uris[0] == "/404.html" ? 404 : 200
    {html: out, status: status}
  end

  def google_folders
    folders = []
    begin
      (files, page_token) = @site.google_session.files(
        page_token: page_token,
        q:'mimeType = "application/vnd.google-apps.folder" and trashed = false and ('+name_query+')'
      )
      folders << files
    end while page_token
    folders = folders.flatten
    folders
  end

  def name_query
    path = strip_query_string @path
    path.split("/").each_with_index.map {|name, index|
      if index != 0
        "name = '#{name}'"
      end
    }.compact.join(" or ")
  end

  def access_token
    @site.db_path.present? ? @site.identity.full_access_token : @site.identity.access_token
  end

  def folder
    @site.db_path.present? ? @site.db_path : '/' + @site.name
  end

  def dropbox_content
    document_root = self.site.document_root || ''
    file_path = folder + '/' + document_root + '/' + @path
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
    Rails.logger.info "Requesting https://#{self.site.name}.updog.co#{file_path.gsub(self.site.name+'/','')}"
    Rails.logger.info "Dropbox file path: #{file_path}"
    Rails.logger.info "Document root: #{self.site.document_root}"
    Rails.logger.info "Db path: #{self.site.db_path}"
    res = HTTParty.post(url, opts)
    oat = res.body.html_safe
    oat = "Not found - Please Reauthenticate Dropbox" if oat.match("Invalid authorization value")
    oat
  end

  def get_temporary_link
    url = 'https://api.dropboxapi.com/2/files/get_temporary_link'
    document_root = self.site.document_root || ''
    file_path = folder + '/' + document_root + '/' + @path
    file_path = file_path.gsub(/\/+/,'/')
    opts = {
      headers: self.class.db_headers(self.site.identity.access_token),
      body: {
        path: file_path
      }.to_json
    }
    res = HTTParty.post(url, opts).body
    JSON.parse(res)["link"]
  end

  def mime status
    extname = File.extname(strip_query_string(@path))[1..-1]
    mime_type = Mime::Type.lookup_by_extension(extname)
    mime_type.to_s unless mime_type.nil?
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

  def subcollection_from_uri uri, dir, session, g_folders
    folders = folders_from_uri uri
    page_token = nil
    last_parent = dir
    folders.each do |folder|
      subcollection = g_folders.select{ |gf|
        gf.parents && gf.parents.include?(last_parent.id) && gf.title == folder
      }.first
      last_parent = subcollection
    end

    last_parent
  end

  def folders_from_uri uri
    all = uri.split("/")
    all.shift # the empty initial slash
    all.pop
    all
  end

  def title_from_uri uri
    folders = uri.split("/")
    folders.pop # the file
  end

  def google_content dir, folders
    filename = strip_query_string(@path)
    file_path = '/' + @site.name + '/' + filename
    file_path = file_path.gsub(/\/+/,'/').gsub(/\?(.*)/,'')
    folda = subcollection_from_uri(@path, dir, @site.google_session, folders) || dir
    title = title_from_uri(filename)
    file = google_file_by_title(folda, title)
    file.nil? ? "Error in call to API function" : download_to_string(file)
  end

  def google_file_by_title folder, title
    folder.file_by_title(title || '')
  end

  def download_to_string file
    begin
      file.download_to_string.html_safe
    rescue Google::Apis::ClientError => e
      e
    end
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
