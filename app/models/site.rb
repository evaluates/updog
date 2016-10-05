class Site < ActiveRecord::Base
  belongs_to :user, :foreign_key => :uid, :primary_key => :uid
  has_many :clicks
  has_paper_trail
  validates :subdomain, uniqueness: { case_sensititve: false }
  validates :name, presence: true
  validates :domain, uniqueness: { case_sensititve: false, allow_blank: true }
  validate :domain_isnt_updog
  validate :domain_is_a_subdomain
  validate :user_has_less_than_5_sites
  before_validation :namify

  def to_param
      "#{id}-#{name.parameterize}"
  end

  def creator
    User.find_by( uid: self.uid )
  end

  def content client, env
    self.clicks.create(data:{
      path: env["REQUEST_URI"],
      ip: env["REMOTE_ADDR"],
      referer: env["HTTP_REFERER"]
    })
    if env['REQUEST_URI'][-1] == "/" && env['PATH_INFO'] != '/404.html'
      path = env['PATH_INFO'] + "/index.html"
    else
      path = env['PATH_INFO']
    end
    path = URI.unescape(path)
    Rails.cache.fetch("#{cache_key}/#{path}", expires_in: 30.seconds) do
      path = path + "index.html" if path == "/"
      self.document_root ||= ''
      client.get_file( self.name + '/' + self.document_root +  path ).html_safe
    end
  end

  def user_has_less_than_5_sites
    if self.user && self.user.sites.length > 4
      errors.add(:number_of_sites, "can't be greater than 5")
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

  private
   def  namify
    self.name.downcase!
    self.name = self.name.gsub(/[^\w+]/,'-')
    self.name = self.name.gsub(/-+$/,'')
    self.name = self.name.gsub(/^-+/,'')
    self.subdomain = self.name + '.updog.co'
  end

end
