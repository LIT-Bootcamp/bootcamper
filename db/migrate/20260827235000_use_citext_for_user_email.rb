class UseCitextForUserEmail < ActiveRecord::Migration[8.1]
  def up
    enable_extension "citext"
    remove_index :users, name: "index_users_on_lower_email"
    change_column :users, :email, :citext, null: false
    add_index :users, :email, unique: true
  end

  def down
    remove_index :users, :email
    change_column :users, :email, :string, null: false
    add_index :users, "LOWER(email)", unique: true, name: "index_users_on_lower_email"
  end
end
