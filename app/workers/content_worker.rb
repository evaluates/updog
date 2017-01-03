class ContentWorker
  include Sidekiq::Worker
  def perform site_id, uri, path, cache_key
    @site = Site.find(site_id)
    Rails.cache.write("#{cache_key}/#{path}",@site.from_api(uri, path, @site.dir))
  end
end
