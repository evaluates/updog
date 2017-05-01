require 'spec_helper'
require 'google_drive'
describe Resource do
  describe ".new" do
    before do
      Site.destroy_all
      @u = User.create
      @u.identities.create!(provider: 'dropbox', email:'test@test.test')
      @u.sites.create!(provider:'dropbox', name: 'jjohn')
      @resource = Resource.new @u.sites.first, '/'
    end
    it "has a uri" do
      expect(@resource.uri).to eq("/")
    end
    it "has a site" do
      expect(@resource.site).to be_an_instance_of(Site)
    end
    it "maps URIs to paths" do
      expect(@resource.path).to eq("/index.html")
      @resource = Resource.new @u.sites.first, '/?say=what'
      expect(@resource.path).to eq("/index.html")
    end
    it "removes duplicate slashes" do
      @resource = Resource.new @u.sites.first, '//'
      expect(@resource.path).to eq("/index.html")
    end
    it "has contents" do
      stub @resource.site.name, @resource.path, 200
      expect(@resource.contents[:html]).to eq(fixture("index.html"))
      out = Rails.cache.fetch("#{@resource.cache_key}/#{@resource.uri}")
      expect(out[:html]).to eq(fixture("index.html"))
    end
    it "has contents when path has space" do
      @resource = Resource.new @u.sites.first, '/a%20file.txt'
      stub @resource.site.name, @resource.path, 200
      expect(@resource.contents[:html]).to eq(fixture("a\ file.txt"))
    end
    it "has a cache key" do
      expect(@resource.cache_key).to eq(@resource.site.updated_at.utc.to_s(:number) + @resource.site.id.to_s)
    end
    it "has an access_token" do
      @resource.site.db_path = 'whatwhat'
      expect(@resource.access_token).to eq(@resource.site.identity.full_access_token)
      @resource.site.db_path = ''
      expect(@resource.access_token).to eq(@resource.site.identity.access_token)
      @resource.site.db_path = nil
      expect(@resource.access_token).to eq(@resource.site.identity.access_token)
    end
    it "has a folder" do
      @resource.site.db_path = 'whatwhat'
      expect(@resource.folder).to eq(@resource.site.db_path)
      @resource.site.db_path = ''
      expect(@resource.folder).to eq('/' + @resource.site.name)
      @resource.site.db_path = nil
      expect(@resource.folder).to eq('/' + @resource.site.name)
    end
    it "gets a filename/title from the uri" do
      title = @resource.title_from_uri '/index.html'
      expect(title).to eq('index.html')
      title = @resource.title_from_uri '/one/two/three/index.html'
      expect(title).to eq('index.html')
    end
    it "gets a list of folders from the uri" do
      folders = @resource.folder_names('/one/two/three/index.html')
      expect(folders).to eq(%w(one two three index.html))
      folders = @resource.folder_names('/index.html')
      expect(folders).to eq(%w(index.html))
    end
    it "can get a temporary dropbox link" do
      @resource = Resource.new @u.sites.first, '/a%20file.zip'
      stub_request(:post, "https://api.dropboxapi.com/2/files/get_temporary_link").
         to_return(:status => 200, :body => fixture('get_temporary_link.json'), :headers => {})
      expect(@resource.get_temporary_link).to match('dl.dropboxusercontent.com')
    end
    it "handles invalid byte sequences" #do
    #   @resource = Resource.new @u.sites.first, '/invalidbytesequence.jpg'
    #   stub @resource.site.name, @resource.path, 200
    #   expect {
    #     @resource.contents
    #   }.not_to raise_error(ArgumentError)
    # end
    it "lists a directory index" do
      @resource = Resource.new @u.sites.first, '/index-me/'
      stub @resource.site.name, @resource.path, 200
      stub_request(:post, "https://api.dropboxapi.com/2/files/search").
        to_return(:status => 200, :body => fixture("search.json"), :headers => {})
      expect(@resource.contents[:html]).to eq("show folders")
    end
    context "creating dropbox content" do
      before do
        stub_request(:post, "https://api.dropboxapi.com/2/files/create_folder").
          to_return(:status => 200, :body => "yo yo yo", :headers => {})
        stub_request(:post, "https://content.dropboxapi.com/2/files/upload").
          to_return(:status => 200, :body => "", :headers => {})
      end
      it "can create a dropbox folder" do
        res = Resource.create_dropbox_folder("pizza","abcd")
        expect(res.code).to eq(200)
      end
      it "can create a dropbox file in that folder" do
        res = Resource.create_dropbox_file("index.html","yo yo yo","abcd")
        expect(res.code).to eq(200)
      end
      it "raises an exception if a file or folder fails to create"
    end
    context "404s" do
      before do
        @resource = Resource.new(@u.sites.first, '/doesnotexist')
        stub404 @resource.site.name, @resource.path, 409
      end
      it "404s if file not found" do
        expect(@resource.contents[:html]).to eq(File.read(Rails.public_path + 'load-404.html'))
        expect(@resource.contents[:status]).to eq(404)
      end
      it "has the right content type for 404s" do
        expect(@resource.contents[:content_type]).to eq("text/html; charset=utf-8")
      end
      it "has the right content type for 404d image" do
        @resource = Resource.new(@u.sites.first, '/doesnotexist.png')
        stub404 @resource.site.name, @resource.path, 409
        expect(@resource.contents[:content_type]).to eq("text/html; charset=utf-8")
      end
      it "serves custom 404 pages"
    end
    context "markdown requests" do
      it "provides some markdown css" do
        @resource = Resource.new(@u.sites.first, '/markdown.css')
        stub404 @resource.site.name, @resource.path, 409
        expect(@resource.contents[:content_type]).to match('text/css')
      end
      it "renders markdown if user is pro and site allows it" do
        @resource = Resource.new(@u.sites.first, '/markdown.md')
        stub @resource.site.name, @resource.path, 200

        @resource.site.user.is_pro = true
        @resource.site.render_markdown = true
        expect(@resource.contents[:html]).to match(fixture('markdown.html').gsub(/\n$/,''))
        expect(@resource.contents[:content_type]).to eq('text/html; charset=utf-8')

        @resource = Resource.new(@u.sites.first, '/raw.md')
        stub @resource.site.name, @resource.path, 200
        @resource.site.render_markdown = false
        expect(@resource.contents[:html]).to match(fixture('raw.md'))
        expect(@resource.contents[:content_type]).to match('text/plain')
      end
      it "doesnt render markdown if ?raw in url" do
        @resource = Resource.new(@u.sites.first, '/markdown.md?raw')
        stub @resource.site.name, @resource.path, 200
        @resource.site.user.is_pro = true
        @resource.site.render_markdown = true

        expect(@resource.contents[:html]).to match(fixture('markdown.md'))
        expect(@resource.contents[:content_type]).to match('text/plain')
      end
    end
    it "has the correct mime_types" do
      mimes = {
        :ico => "image/x-icon",
        :svg => "image/svg+xml",
        :md => "text/plain",
        :mp3 => "audio/mpeg",
        :mp4 => "video/mp4",
        :epub => "application/epub+zip",
        :txt => "text/plain",
        :mobi => "application/x-mobipocket-ebook",
        :rar => "application/x-rar-compressed",
        :rtf => "application/rtf",
        :swf => "application/x-shockwave-flash",
        :doc => "application/msword",
        :dot => "application/msword",
        :docx => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        :dotx => "application/vnd.openxmlformats-officedocument.wordprocessingml.template",
        :docm => "application/vnd.ms-word.document.macroenabled.12",
        :dotm => "application/vnd.ms-word.template.macroenabled.12",
        :xls => "application/vnd.ms-excel",
        :xlt => "application/vnd.ms-excel",
        :xla => "application/vnd.ms-excel",
        :xlsx => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        :xltx => "application/vnd.openxmlformats-officedocument.spreadsheetml.template",
        :xlsm => "application/vnd.ms-excel.sheet.macroenabled.12",
        :xltm => "application/vnd.ms-excel.template.macroenabled.12",
        :xlam => "application/vnd.ms-excel.addin.macroenabled.12",
        :xlsb => "application/vnd.ms-excel.sheet.binary.macroenabled.12",
        :ppt => "application/vnd.ms-powerpoint",
        :pptx => "application/vnd.openxmlformats-officedocument.presentationml.presentation",
        :jar => "application/java-archive",
        :jnlp => "application/x-java-jnlp-file",
        :smc => "application/octet-stream",
        :oga => "audio/ogg",
        :ogv => "video/ogg",
        :ogg => "audio/ogg",
        :eot => "application/vnd.ms-fontobject",
        :otf => "application/x-font-otf",
        :ttf => "application/x-font-ttf",
        :woff => "application/font-woff",
        :woff2 => "font/woff2",
        :webm => "video/webm"
      }
      mimes.each do |extension, mime_type|
        @resource = Resource.new(@u.sites.first, '/example.' + extension.to_s)
        puts "#{extension} should be #{mime_type}"
        expect(@resource.mime(200)).to match(mime_type)
      end

    end
    it "handles all the encodings" do
      user_string = URI.decode('%D0%9C').force_encoding('ISO-8859-1')
      rails_saw = user_string.force_encoding("ASCII-8BIT")
      @resource = Resource.new(@u.sites.first, '/' + rails_saw)
      stub @resource.site.name, @resource.path, 200
      expect(@resource.contents[:status]).to eq(200)
    end
    context "google" do
      before do
        @u = User.create
        @u.identities.create!(provider: 'google', email:'test@test.test')
        @site = @u.sites.create!(provider:'google', name: 'jjjjohn')
        @resource = Resource.new @site, '/'
        @resource2 = Resource.new @site, '/a/really/long/url/'
      end
      it "has contents" do
        allow(@resource).to receive(:subcollection_from_uri) {nil}
        allow(@resource).to receive(:google_file_by_title) {"index.html"}
        allow(@resource).to receive(:download_to_string) {fixture("index.html")}
        allow(@resource).to receive(:google_folders) {[]}
        allow(@resource).to receive(:google_content) {fixture("index.html")}
        allow(@resource.site).to receive(:dir){nil}
        expect(@resource.contents[:html]).to eq(fixture("index.html"))
      end
      it "contstructs a names query based on path" do
        expect(@resource.build_query(@resource.path)).to eq("name = 'index.html'")
        expect(@resource2.build_query(@resource2.path)).to eq("name = 'a' or name = 'really' or name = 'long' or name = 'url' or name = 'index.html'")
      end
      it "handles rate limit violations gracefully" do
        @resource = Resource.new @site, '/?something=brand-new'
        allow(@resource).to receive(:google_folders) { raise Google::Apis::RateLimitError.new 'Rate limit exceeded'}
        allow(@resource.site).to receive(:dir) { raise Google::Apis::RateLimitError.new 'Rate limit exceeded'}
        expect{@resource.contents}.not_to raise_error
      end
    end
  end
end
