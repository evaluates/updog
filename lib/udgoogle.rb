module Udgoogle
  def json files, path
    files.map{|file|
      {
        "title" => file.title,
        ".tag" => tag_from_mime_type(file.mime_type),
        "path_lower" => (path + "/" + file.title).gsub(/\/\//,'/')
    }}
  end
  def tag_from_mime_type mime_type
    mime_type == "application/vnd.google-apps.folder" ? "folder" : "file"
  end
  def google_session site
    if site.provider == 'google'
      identity = site.user.identities.find_by(provider: site.provider)
      GoogleDrive::Session.from_access_token(identity.access_token)
    end
  end
  def collection_from_path session, path, g_folders
    folders = folder_names path
    last_parent_id = @site.google_id
    folders.each do |folder|
      subcollection = g_folders.select{ |gf|
        value = (is_subchild?(gf, last_parent_id) || gf.id == last_parent_id) && gf.title == folder
        value
      }.first unless g_folders.nil?
      last_parent_id = subcollection.nil? ? last_parent_id : subcollection.id
    end
    collection = g_folders.select{|folder| folder.id == last_parent_id }.first unless g_folders.nil?
    collection
  end
  def is_subchild? gf, parent_id
    gf.parents && gf.parents.include?(parent_id)
  end
  def google_folders session, query_string, site
    foldrs = []
    page_token = nil
    begin
      begin
        (files, page_token) = session.files(
          page_token: page_token,
          q:'trashed = false and ('+query_string+')'
        )
      rescue => e
        if e.to_s == "Unauthorized"
          site.identity.refresh_access_token
          return google_folders(google_session(site), query_string, site)
        else
          Rails.logger.warn e
        end
      end
      foldrs << files
    end while page_token
    foldrs = foldrs.flatten
    foldrs
  end
  def folder_names path
    names = path.split("/")
    names = names.map{|name|
      name if name.present?
    }.compact
    names
  end
  def title_from_uri uri
    folders = uri.split("/")
    folders.pop # the file
  end
  def build_query path
    path.split("/").each_with_index.map do |name, index|
      if index != 0
        "name = '#{name}'"
      end
    end.compact.join(" or ")
  end
  def google_content dir, folders, sesh
    filename = strip_query_string(@path)
    file_path = '/' + @site.name + '/' + filename
    file_path = file_path.gsub(/\/+/,'/').gsub(/\?(.*)/,'')
    folda = collection_from_path(sesh, @path, folders) || dir
    title = title_from_uri(filename)
    file = google_file_by_title(folda, title)
    file.nil? ? "Error in call to API function" : file
  end
  def google_file_by_title folder, title
    begin
      folder.download_to_string.html_safe unless folder.nil?
    rescue => e
      Rails.logger.error(e.to_s)
      "Error in call to API function"
    end
  end

  def parse_timings times
    sorted = times.sort_by do |key, value|
      value
    end
    sorted = sorted.each_with_index.map do |pair, index|
      key = pair[0]
      value = pair[1]
      if index == 0
        [key, 0]
      else
        value = value - sorted[index-1][1]
        [key, value]
      end
    end.to_h
  end
end
