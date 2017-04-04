# Be sure to restart your server when you modify this file.
require 'webrick/httputils'
begin
  list = WEBrick::HTTPUtils.load_mime_types('/etc/mime.types')
rescue Errno::ENOENT
  list = WEBrick::HTTPUtils.load_mime_types('/etc/apache2/mime.types')
end
list.merge!({
  "md" => "text/plain",
  "ppt" => "application/vnd.ms-powerpoint",
  "woff2" => "font/woff2"
})
Rack::Mime::MIME_TYPES.merge!(list)

# Add new mime types for use in respond_to blocks:
