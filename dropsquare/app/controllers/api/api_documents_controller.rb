class Api::ApiDocumentsController < Api::BaseController
  before_filter :find_folder, :only => [:create, :update, :destroy, :download_file, :download_files]
  before_filter :find_document, :only => [:update, :destroy, :download_file]

  def create
    user = current_user
    ActiveRecord::Base.transaction do
      params["file_name"].each do |file|
        document = @folder.documents.create(:file_name => file, :user_id => user.id)
        raise "Cannot save new document" unless document
      end
    end
    folder_hash = {folder_name: @folder.name, folder_id: @folder.id,
                   documents: generate_folder_json(@folder)}
    resp = {return_code: 1, error_msg: "File successfully uploaded"}
    resp = resp.merge("folder" => folder_hash)
  rescue Exception => e
    resp = {return_code: 0, error_msg: e.message}
  ensure
    render json: MultiJson.dump(resp)
  end

  def update
    user = current_user
    if @document.update_attributes(:file_name => params["file_name"])
      folder_hash = {folder_name: @folder.name, folder_id: @folder.id,
                   documents: generate_folder_json(@folder)}
      resp = {return_code: 1, error_msg: "Document successfully updated"}
      resp = resp.merge("folder" => folder_hash)
    end
  rescue Exception => e
    resp = {return_code: 0, error_msg: e.message}
  ensure
    render json: MultiJson.dump(resp)
  end

  def destroy
    user = current_user
    if @document.destroy
      folder_hash = {folder_name: @folder.name, folder_id: @folder.id,
                   documents: generate_folder_json(@folder)}
      resp = {return_code: 1, error_msg: "Document successfully deleted"}
      resp = resp.merge("folder" => folder_hash)
    end
  rescue Exception => e
    resp = {return_code: 0, error_msg: e.message}
  ensure
    render json: MultiJson.dump(resp)
  end

  def download_file
    url = "#{Rails.root.join('public')}#{@document.file_name.url}"
    resp = {return_code: 1, error_msg: e.message, url: url}
  rescue Exception => e
    resp = {return_code: 0, error_msg: e.message}
  ensure
    render json: MultiJson.dump(resp)
  end

  def download_files
    documents = @folder.documents.where("id in (?)", params[:doc_ids])

    filename = "archive_#{Time.now.to_s(:db)}.zip"
    temp_file = Tempfile.new(filename, "#{Rails.root.join('public/archive')}")

    Zip::File.open(temp_file.path, Zip::File::CREATE) do |zipfile|
      @old_name = ""
      i = 0
      documents.each do |document|
        new_name = @old_name == document.file_name.file.filename ? (i+=1;"#{i}##{@old_name}") : document.file_name.file.filename
        @old_name = document.file_name.file.filename
        zipfile.add(new_name, "#{Rails.root.join('public')}#{document.file_name.url}")
      end
    end
    
    url = temp_file.path
    resp = {return_code: 1, error_msg: '', url: url}
  rescue Exception => e
    resp = {return_code: 0, error_msg: e.message}
  ensure
    render json: MultiJson.dump(resp)
  end

  private

    def find_folder
      @folder = current_user.folders.find_by_id(params[:folder_id])
      if @folder.nil?
        resp = {return_code: 0, error_msg: "Cannot Find the Folder or You don't Have Authorized to Manage the Folder"}
        render json: MultiJson.dump(resp)
      end
    end

    def find_document
      @document = @folder.documents.find_by_id(params[:id])
      if @document.nil?
        resp = {return_code: 0, error_msg: "Cannot Find the Document or You don't Have Authorized to Manage the Document"}
        render json: MultiJson.dump(resp)
      end
    end

    def generate_folder_json(folder)
      base64_images = []
      folder.documents.each do |document|
        address = "#{Rails.root.join('public')}#{document.file_name.url}"
        ext = document.file_name.file.extension.downcase
        type = %w{jpg png jpeg gif bmp}.include?(ext) ? 'image' : 'application'
        encoded_file = 'aaa'#"data:#{type}/#{ext};base64,#{Base64.encode64(File.open(address, "rb").read)}"
        base64_images << {doc_id: document.id, doc_name: document.file_name.file.filename,
                          doc_encoded: encoded_file}
      end
      return base64_images
    end
end
