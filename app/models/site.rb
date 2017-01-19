require 'resolv'

class Site < ActiveRecord::Base
  belongs_to :user
  attr_accessor :passcode
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

  before_save :encrypt_password
  after_save :clear_password

  def encrypt_password
    if passcode.present?
      self.encrypted_passcode= Digest::SHA2.hexdigest(passcode)
    end
  end

  def clear_password
    self.passcode = nil
  end

  def to_param
    "#{id}-#{name.parameterize}"
  end

  def creator
    self.user
  end

  def identity
    Identity.find_by(user: self.user, provider: self.provider)
  end

  def content path, dir = nil
    Resource.new(self, path).contents
  end

  def inject?
    (!self.creator.is_pro && self.creator.id > 1547) || !Rails.env.production?
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

  def base_path
    case
    when self.document_root.present?
      self.document_root
    when self.db_path.present?
      self.db_path
    else
      "/" + self.name
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

  def dir folders
    folders.select{|folder| folder.id == self.google_id }.first if self.provider == 'google'
  end

  def domain_cname
    Resolv::DNS.open do |dns|
      records = dns.getresources(self.domain, Resolv::DNS::Resource::IN::CNAME)
      value = records.empty? ? nil : records.select{|record|
        record.name.to_s == 'updog.co'
      }.first
      value.name.to_s unless value.nil?
    end
  end

  def domain_configuration
    return nil unless self.domain.present?
    case
    when domain_cname.nil?
      {text:"There is no CNAME entry for #{self.domain}", klass: 'red'}
    when domain_cname != 'updog.co'
      {text:"The CNAME entry for #{self.domain} does not point to updog.co", klass: 'red'}
    else
      {text:"You have configured your domain correctly.", klass: 'green'}
    end
  end

  def protocol
    if self.domain.present?
      'http://'
    else
      'https://'
    end
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
