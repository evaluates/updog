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
    it "handles contents errors gracefully" do
      allow(@resource).to receive(:from_api){ Error.new 'shit' }
      expect(@resource.contents[:html]).to eq('An unknown error occurred. Please try again later.')
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
      folders = @resource.folders_from_uri('/one/two/three/index.html')
      expect(folders).to eq(%w(one two three))
      folders = @resource.folders_from_uri('/index.html')
      expect(folders).to eq([])
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
        allow(@resource.site).to receive(:dir){nil}
        expect(@resource.contents[:html]).to eq(fixture("index.html"))
      end
      it "contstructs a names query based on path" do
        expect(@resource.name_query).to eq("name = 'index.html'")
        expect(@resource2.name_query).to eq("name = 'a' or name = 'really' or name = 'long' or name = 'url' or name = 'index.html'")
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
