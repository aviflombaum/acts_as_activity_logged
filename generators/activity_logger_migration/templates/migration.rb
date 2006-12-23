class <%= class_name %> < ActiveRecord::Migration
  def self.up
    create_table :activity_logs, :options => "DEFAULT CHARSET = utf8" do |t|
      t.column :user_id, :integer
      t.column :activity_loggable_type, :string
      t.column :activity_loggable_id, :integer
      t.column :action, :string
      t.column :created_at, :datetime
      t.column :culprit_id, :integer
      t.column :culprit_type, :string
      t.column :referenced_id, :integer
      t.column :referenced_type, :string
    end
  end

  def self.down
    drop_table :activity_logs
  end
end
