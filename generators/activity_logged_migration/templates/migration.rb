class <%= class_name %> < ActiveRecord::Migration
  def self.up
    create_table :activity_logs, :options => "DEFAULT CHARSET = utf8" do |t|
      # Thanks to 'Justin' for an updated migration script, much cleaner!
      t.belongs_to :user 
      t.string :action 
      t.references :activity, :null => false, :polymorphic => true 
      t.references :culprit, :null => false, :polymorphic => true 
      t.references :referenced, :null => false, :polymorphic => true 
      t.timestamps 
    end
  end

  def self.down
    drop_table :activity_logs
  end
end