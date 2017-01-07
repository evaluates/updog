class ContentWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false
  def perform site_id, path, cache_key
    @site = Site.find(site_id)
    @content = @site.content(path)
    @resource = Resource.new @site, path
    content = @resource.from_api
    @site.touch
    Rails.cache.write("#{@resource.cache_key}/#{path}", content)
  end
end
