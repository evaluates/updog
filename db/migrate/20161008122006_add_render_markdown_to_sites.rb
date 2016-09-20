class AddRenderMarkdownToSites < ActiveRecord::Migration
  def change
    add_column :sites, :render_markdown, :boolean
  end
end
