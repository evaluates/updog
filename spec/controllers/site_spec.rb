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
      @request.env['PATH_INFO'] = '/index.html'
    end
    it "loads a site" do
      get :load
      expect(response.status).to eq(200)
    end
    it "404s for nonexistent files" do
      @request.env['PATH_INFO'] = '/somethingthatdoesntexist'
      get :load
      expect(response.status).to eq(404)
    end
    it "has the right content type for 404s" do
      @request.env['PATH_INFO'] = '/somethingthatdoesntexist'
      get :load
      expect(response.header['Content-Type']).to match('text/html')
    end
    it "has the right content type for 404d image" do
      @request.env['PATH_INFO'] = '/somethingthatdoesntexist.png'
      get :load
      expect(response.header['Content-Type']).to match('text/html')
    end
    it "has html 404 pages" do
      @request.env['PATH_INFO'] = '/somethingthatdoesntexist'
      get :load
      expect(response.body).to match('<!DOCTYPE')
    end
    it "provides some markdown css" do
      @request.env['PATH_INFO'] = '/markdown.css'
      get :load
      expect(response.header['Content-Type']).to match('text/css')
    end
  end
end
