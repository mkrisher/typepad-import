class EntryColumnTypes < ActiveRecord::Migration
  def self.up
    change_column :entries, :description, :text
    change_column :entries, :content, :text
  end

  def self.down
    change_column :entries, :description, :string
    change_column :entries, :content, :string
  end
end
