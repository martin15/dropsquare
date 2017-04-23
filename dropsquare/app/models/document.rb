class Document < ActiveRecord::Base
  mount_base64_uploader :file_name, DocumentUploader

  belongs_to :folder
  belongs_to :user
end
