class Document < ActiveRecord::Base
  mount_uploader :file_name, DocumentUploader

  belongs_to :folder
  belongs_to :user
end
