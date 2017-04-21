class CreateDocuments < ActiveRecord::Migration
  def change
    create_table :documents do |t|
      t.string :file_name
      t.integer :user_id
      t.integer :folder_id
      t.timestamps null: false
    end
  end
end
