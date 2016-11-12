require 'kramdown'
require 'rouge'

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

  def content env
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
    expires_in = self.creator && self.creator.is_pro?  ? 5.seconds : 30.seconds
    Rails.cache.fetch("#{cache_key}/#{path}", expires_in: expires_in) do
      document_root = self.document_root || ''
      file_path = '/' + self.name + '/' + document_root + '/' + path
      file_path = file_path.gsub(/\/+/,'/')
      url = 'https://content.dropboxapi.com/2/files/download'
      at = self.creator && self.creator.access_token
      opts = {
      	headers: {
      	  'Authorization' => "Bearer #{at}",
      	  'Content-Type' => '',
      	  'Dropbox-API-Arg' => {
      	    path: file_path
      	  }.to_json
      	}
      }
      res = HTTParty.post(url, opts)
      oat = res.html_safe
      oat = "Not found" if oat.match("Invalid authorization value")
      begin
        if file_path.match(/\.(md|markdown)$/) && !env['QUERY_STRING'].match(/raw/) && self.creator.is_pro? && self.render_markdown
  	      oat = markdown(oat)
        end
        oat
      rescue
        "Not Found"
      end
    end
  end

  def markdown content
    md = Kramdown::Document.new(content.force_encoding('utf-8'),
      input: 'GFM',
      syntax_highlighter: 'rouge',
      syntax_highlighter_opts: {
	formatter: Rouge::Formatters::HTML
    }).to_html
    preamble = "<!doctype html><html><head><meta name='viewport' content='width=device-width'><meta charshet='utf-8'><link rel='stylesheet' type='text/css' href='/markdown.css'></head><body>"
    footer = "</body></html>"
    (preamble + md + footer).html_safe
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
