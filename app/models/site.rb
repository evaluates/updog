class Site < ActiveRecord::Base
  belongs_to :user, :foreign_key => :uid, :primary_key => :uid
  has_many :clicks
  has_many :contacts
  has_paper_trail
  validates :subdomain, uniqueness: { case_sensititve: false }
  validates :name, presence: true
  validates :domain, uniqueness: { case_sensititve: false, allow_blank: true }
  validate :domain_isnt_updog
  validate :domain_is_a_subdomain
  before_validation :namify
  after_create :notify_drip

  def to_param
      "#{id}-#{name.parameterize}"
  end

  def creator
    User.find_by( uid: self.uid )
  end

  def index path
    path = path.gsub('/directory-index.html','')
    url = 'https://api.dropboxapi.com/2/files/list_folder'
    if self.db_path && self.db_path != ""
      at = self.creator && self.creator.full_access_token
      folder = self.db_path
    else
      at = self.creator && self.creator.access_token
      folder = '/' + self.name
    end
    old_path = path
    document_root = self.document_root || ''
    file_path = folder + '/' + document_root + '/' + path
    file_path = file_path.gsub(/\/+/,'/')

    opts = {
      headers: {
	'Authorization' => "Bearer #{at}",
	'Content-Type' => 'application/json',
      },
      body: {
	path: file_path
      }.to_json
    }
    res = HTTParty.post(url, opts)
    res["entries"] = res["entries"].select{|entry| entry["name"] != 'directory-index.html'}
    res.merge("path" => path)
  end

  def content uri
    path = URI.unescape(uri)
    expires_in = self.creator && self.creator.is_pro?  ? 5.seconds : 30.seconds
    Rails.cache.fetch("#{cache_key}/#{path}", expires_in: expires_in) do
      if self.db_path && self.db_path != ""
        at = self.creator && self.creator.full_access_token
        folder = self.db_path
      else
        at = self.creator && self.creator.access_token
        folder = '/' + self.name
      end
      document_root = self.document_root || ''
      file_path = folder + '/' + document_root + '/' + path
      file_path = file_path.gsub(/\/+/,'/')
      url = 'https://content.dropboxapi.com/2/files/download'
      opts = {
      	headers: {
      	  'Authorization' => "Bearer #{at}",
      	  'Content-Type' => '',
      	  'Dropbox-API-Arg' => {
      	    path: file_path
      	  }.to_json
      	}
      }
      logger.info "Requesting https://#{self.name}.updog.co#{file_path.gsub(self.name+'/','')}"
      logger.info "Dropbox file path: #{file_path}"
      logger.info "Document root: #{self.document_root}"
      logger.info "Db path: #{self.db_path}"
      res = HTTParty.post(url, opts)
      oat = res.body.html_safe
      oat = "Not found - Please Reauthenticate Dropbox" if oat.match("Invalid authorization value")
      oat
    end
  end

  def domain_isnt_updog
    if self.domain =~ /updog\.co/
      errors.add(:domain, "can't contain updog.co")
    end
  end

  def domain_is_a_subdomain
    if self.domain && self.domain != "" && self.domain !~ /\w+\.[\w-]+\.\w+/
      errors.add(:domain, "must have a subdomain like www.")
    end
  end

  def link
    if self.domain && self.domain != ""
      self.domain
    else
      self.subdomain
    end
  end
  def self.created_today
    where("created_at > ?", Time.now.beginning_of_day)
  end
  def self.popular
    joins(:clicks).
    group("sites.id").
    where("clicks.created_at > ?", Time.now.beginning_of_day).
    order("count(clicks.id) DESC").
    limit(10)
  end
  def clicks_today
    clicks.where('created_at > ?', Time.now.beginning_of_day)
  end

  private
  def notify_drip
    Drip.event self.creator.email, 'created a site'
  end
   def  namify
    self.name.downcase!
    self.name = self.name.gsub(/[^\w+]/,'-')
    self.name = self.name.gsub(/-+$/,'')
    self.name = self.name.gsub(/^-+/,'')
    self.subdomain = self.name + '.updog.co'
  end

end
