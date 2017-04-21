class Folder < ActiveRecord::Base
  has_many :documents
  accepts_nested_attributes_for :documents

  belongs_to :user
end
