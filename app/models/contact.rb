class Contact < ActiveRecord::Base
  belongs_to :site
  serialize :params
end
