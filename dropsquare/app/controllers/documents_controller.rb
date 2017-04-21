require 'rubygems'
require 'zip'

class DocumentsController < ApplicationController
  before_filter :find_document, :only => [:edit, :update, :destroy, :delete]
  before_filter :find_folder

  def index
    @documents = @folder.documents.order("#{sort_column} #{sort_direction}").page(params[:page]).per(20)
    @no = paging(20)
  end

  def new
    @document = Document.new
  end

  def create
    ActiveRecord::Base.transaction do
      params[:document][:file_name].each do |file|
        @folder.documents.create!(:file_name => file, :user_id => current_user.id)
      end
    end
    flash[:notice] = 'Documents was successfully create.'
    redirect_to documents_path
  rescue Exception => e
    flash[:error] = "Documents failed to create"
    render :action => :new
  end

  def edit
  end

  def update
    if @document.update_attributes(document_params)
      flash[:notice] = 'Document was successfully updated.'
      redirect_to documents_path
    else
      flash[:error] = "Document failed to update"
      render :action => :edit
    end
  end

  def destroy
    flash[:notice] =  @document.destroy ? 'Document was successfully deleted.' :
                                           'Document was falied to delete.'
    redirect_to documents_path
  end

  def download_selected_documents
    documents = @folder.documents.where("id in (?)", params[:doc_ids])

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

  private

    def document_params
      params.require(:document).permit(:file_name)
    end

    def find_document
      @document = current_user.documents.find_by_id(params[:document_id])
      if @document.nil?
        flash[:notice] = "Cannot find the Document with id '#{params[:document_id]}'"
        redirect_to documents_path
      end
    end

    def find_folder
      @folder = current_user.folders.find_by_id(params[:id])
      if @folder.nil?
        flash[:notice] = "Cannot find the Folder with id '#{params[:id]}'"
        redirect_to folder_path
      end
    end

    def sort_column
      params[:sort] || "created_at"
    end

    def sort_direction
      params[:direction] || "desc"
    end
end
