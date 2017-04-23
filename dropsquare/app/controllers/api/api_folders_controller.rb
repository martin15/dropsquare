class Api::ApiFoldersController < Api::BaseController
  before_filter :find_folder, :only => [:update, :destroy, :download_all_documents]

  def index
    user = current_user
    folders = user.folders
    resp = {return_code: 1, error_msg: ""}
    folder_array = []
    folders.each do |folder|
      base64_images = generate_folder_json(folder)
      folder_array << {folder_name: folder.name, folder_id: folder.id, documents: base64_images}
    end
    resp = resp.merge("folders" => folder_array)
  rescue Exception => e
    resp = {return_code: 0, error_msg: e.message}
  ensure
    render json: MultiJson.dump(resp)
  end

  def update
    if @folder.update_attributes(:name => params[:new_folder_name])
      folder_hash = {folder_name: @folder.name, folder_id: @folder.id, 
                     documents: generate_folder_json(@folder)}
      resp = {return_code: 1, error_msg: "Folder successfully updated"}
      resp = resp.merge("folder" => folder_hash)
    end
  rescue Exception => e
    resp = {return_code: 0, error_msg: e.message}
  ensure
    render json: MultiJson.dump(resp)
  end

  def download_all_documents
    documents = @folder.documents

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
      @folder = current_user.folders.find_by_id(params[:id])
      if @folder.nil?
        resp = {return_code: 0, error_msg: "Cannot Find the Folder or You don't Have Authorized to Manage the Folder"}
        render json: MultiJson.dump(resp)
      end
    end

    def generate_folder_json(folder)
      base64_images = []
      folder.documents.each do |document|
        address = "#{Rails.root.join('public')}#{document.file_name.url}"
        ext = document.file_name.file.extension.downcase
        type = %w{jpg png jpeg gif bmp}.include?(ext) ? 'image' : 'application'
        encoded_file = "data:#{type}/#{ext};base64,#{Base64.encode64(File.open(address, "rb").read)}"
        base64_images << {doc_id: document.id, doc_name: document.file_name.file.filename,
                          doc_encoded: encoded_file}
      end
      return base64_images
    end
end
