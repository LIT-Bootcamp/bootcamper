class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |table|
      table.string :email, null: false
      table.string :role, null: false, default: "student"
      table.timestamps
    end

    add_check_constraint :users, "role IN ('student', 'admin')", name: "users_role_check"
    add_index :users, "LOWER(email)", unique: true, name: "index_users_on_lower_email"
  end
end
