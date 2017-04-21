class FoldersController < ApplicationController
  before_filter :find_folder, :only => [:edit, :update, :destroy, :delete, :download_all_documents]

  def index
    @folders = current_user.folders.includes(:documents).order("#{sort_column} #{sort_direction}").
                            page(params[:page]).per(20)
    @no = paging(20)
  end

  def new
    @folder = Folder.new
  end

  def create
    @folder = Folder.new(folder_params)
    puts @folder.inspect
    @folder.user = current_user
    if @folder.save
      params[:folder]['file_name'].each do |file|
        @folder.documents.create!(:file_name => file, :user_id => current_user.id)
      end
      flash[:notice] = 'Folder was successfully create.'
      redirect_to folders_path
    else
      flash[:error] = "Folder failed to create"
      render :action => :new
    end
  end

  def edit
  end

  def update
    if @folder.update_attributes(folder_params)
      flash[:notice] = 'Folder was successfully updated.'
      redirect_to folders_path
    else
      flash[:error] = "Folder failed to update"
      render :action => :edit
    end
  end

  def destroy
    flash[:notice] =  @folder.destroy ? 'Folder was successfully deleted.' :
                                        'Folder was falied to delete.'
    redirect_to folders_path
  end

  def download_all_documents
    documents = @folder.documents

    filename = "archive_#{Time.now.to_s(:db)}.zip"
    temp_file = Tempfile.new(filename)

    Zip::File.open(temp_file.path, Zip::File::CREATE) do |zipfile|
      documents.each do |document|
        zipfile.add(document.file_name.file.filename, "#{Rails.root.join('public')}#{document.file_name.url}")
      end
    end
    zip_data = File.read(temp_file.path)
    send_data(zip_data, :type => 'application/zip', :filename => filename)
  end

  def download_selected_folders
    folders = current_user.folders.where("id in (?)", params[:folder_ids])

    filename = "archive_#{Time.now.to_s(:db)}.zip"
    temp_file = Tempfile.new(filename)

    Zip::File.open(temp_file.path, Zip::File::CREATE) do |zipfile|
      folders.each do |folder|
        folder.documents.each do |document|
          zipfile.add("#{folder.name}/#{document.file_name.file.filename}",
                      "#{Rails.root.join('public')}#{document.file_name.url}")
        end
      end
    end
    zip_data = File.read(temp_file.path)
    send_data(zip_data, :type => 'application/zip', :filename => filename)
  end

  private

    def folder_params
      params.require(:folder).permit(:name, :user_id, :document)
    end

    def find_folder
      @folder = current_user.folders.find_by_id(params[:id])
      if @folder.nil?
        flash[:notice] = "Cannot find the Folder with id '#{params[:id]}'"
        redirect_to folders_path
      end
    end

    def sort_column
      params[:sort] || "created_at"
    end

    def sort_direction
      params[:direction] || "desc"
    end
end
