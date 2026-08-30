class AddProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :display_name, :string
    add_column :users, :technical_skills, :text
    add_column :users, :interests, :text
    add_column :users, :github_url, :string
    add_column :users, :profile_urls, :text
  end
end
