class Resource
  def self.create site, content
    if site.provider == 'dropbox'
      db_put site, content
    end
    if site.provider == 'google'
      gd_put site, content
    end
  end
  def self.gf_put site, content
    access_token = site.creator.identities.find_by(provider:'google').access_token
    session = GoogleDrive::Session.from_access_token(access_token)
    oat=session.upload_from_file(content, "index.html", convert: false)
  end
  def self.db_put site, content
    url = 'https://api.dropboxapi.com/2/files/create_folder'
    access_token = site.creator.identities.find_by(provider:'dropbox').access_token
    opts = {
      headers: db_headers(access_token),
      body: {
        path: site.name
      }.to_json
    }
    HTTParty.post(url, opts)
    url = 'https://content.dropboxapi.com/2/files/upload'
    opts = {
        headers: {
        'Authorization' => "Bearer #{access_token}",
        'Content-Type' =>  'application/octet-stream',
        'Dropbox-API-Arg' => {
          path: '/' + site.name + '/index.html',
        }.to_json
      },
      body: File.read(content)
    }
    HTTParty.post(url, opts)
  end
  def self.db_headers access_token
    {
      'Authorization' => "Bearer #{access_token}",
      'Content-Type' => 'application/json'
    }
  end
end
