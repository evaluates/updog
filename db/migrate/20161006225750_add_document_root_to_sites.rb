require 'dropbox_sdk'
class AddDocumentRootToSites < ActiveRecord::Migration
  def change
    add_column :sites, :document_root, :string
    Site.all.each do |site|
      p "getting #{site.name}"
      begin
        site.content(DropboxClient.new(site.creator.access_token),
          {
            'REQUEST_URI' => '/_config.yml',
            'REMOTE_ADDR' => '127.0.0.1',
            'HTTP_REFERER' => '',
            'PATH_INFO' => '/_config.yml'
          }
        )
        site.update(document_root: '_site/')
      rescue => e
        p e
      end
    end
  end
end
