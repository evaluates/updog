require 'redcarpet'
require 'rouge'
require 'rouge/plugins/redcarpet'

class HTMLR < Redcarpet::Render::HTML
    include Rouge::Plugins::Redcarpet
    def block_code(code, language)
      Rouge.highlight(code, language || 'text', 'html')
    end
end

class Site < ActiveRecord::Base
  belongs_to :user, :foreign_key => :uid, :primary_key => :uid
  has_many :clicks
  has_paper_trail
  validates :subdomain, uniqueness: { case_sensititve: false }
  validates :name, presence: true
  validates :domain, uniqueness: { case_sensititve: false, allow_blank: true }
  validate :domain_isnt_updog
  validate :domain_is_a_subdomain
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
    expires_in = self.creator.is_pro?  ? 5.seconds : 30.seconds
    Rails.cache.fetch("#{cache_key}/#{path}", expires_in: expires_in) do
      path = path + 'index.html' if path == '/'
      document_root = self.document_root || ''
      file_path = self.name + '/' + document_root + '/' + path
      file_path = file_path.gsub(/\/+/,'/')
      oat = client.get_file( file_path ).html_safe
      if file_path.match(/\.(md|markdown)$/) && !env['QUERY_STRING'].match(/raw/) && self.creator.is_pro? && self.render_markdown
	oat = markdown(oat)
      end
      oat
    end
  end

  def markdown content
    render_options = {
      filter_html:     true,
      hard_wrap:       true,
      link_attributes: { rel: 'nofollow' },
      with_toc_data:      true
    }
    renderer = HTMLR.new(render_options)

    extensions = {
      autolink:           true,
      fenced_code_blocks: true,
      lax_spacing:        true,
      no_intra_emphasis:  true,
      strikethrough:      true,
      superscript:        true
    }
    md = Redcarpet::Markdown.new(renderer, extensions).render(content).html_safe
    preamble = "<!doctype html><html><head><meta name='viewport' content='width=device-width;'><meta charshet='utf-8'><link rel='stylesheet' type='text/css' href='/markdown.css'></head><body>"
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

  private
   def  namify
    self.name.downcase!
    self.name = self.name.gsub(/[^\w+]/,'-')
    self.name = self.name.gsub(/-+$/,'')
    self.name = self.name.gsub(/^-+/,'')
    self.subdomain = self.name + '.updog.co'
  end

end
