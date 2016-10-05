class AddDocumentRootToSite < ActiveRecord::Migration
  def change
    add_column :sites, :document_root, :string
  end
end
