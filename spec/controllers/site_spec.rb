require 'spec_helper'

describe SitesController do
  describe "GET load" do
    before do
      Site.destroy_all
      Identity.destroy_all
      User.destroy_all
      u = User.create
      u.identities.create!(access_token:ENV['db_access_token'], provider: 'dropbox', email:'test@test.test')
      u.sites.create(domain:'www.jomdog.com', name:'jom', provider:'dropbox')
      @request.host = 'www.jomdog.com'
      @request.env['REQUEST_PATH'] = '/index.html'
    end
    it "loads a site" do
      get :load
      expect(response.status).to eq(200)
    end
    it "404s for nonexistent files" do
      @request.env['REQUEST_PATH'] = '/somethingthatdoesntexist'
      get :load
      expect(response.status).to eq(404)
    end
    it "has the right content type for 404s" do
      @request.env['REQUEST_PATH'] = '/somethingthatdoesntexist'
      get :load
      expect(response.header['Content-Type']).to match('text/html')
    end
    it "has the right content type for 404d image" do
      @request.env['REQUEST_PATH'] = '/somethingthatdoesntexist.png'
      get :load
      expect(response.header['Content-Type']).to match('text/html')
    end
    it "has html 404 pages" do
      @request.env['REQUEST_PATH'] = '/somethingthatdoesntexist'
      get :load
      expect(response.body).to match('<!DOCTYPE')
    end
    it "provides some markdown css" do
      @request.env['REQUEST_PATH'] = '/markdown.css'
      get :load
      expect(response.header['Content-Type']).to match('text/css')
    end
    it "handles all the encodings" do
      user_string = URI.decode('%D0%9C').force_encoding('ISO-8859-1')
      rails_saw = user_string.force_encoding("ASCII-8BIT")
      @request.env['REQUEST_PATH'] = rails_saw
      get :load
      expect(response.status).to eq(404)
    end
  end
end
