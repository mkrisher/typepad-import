class UpdateEntries < ActiveRecord::Migration
  def self.up
    drop_table :entries
    create_table :entries, :force => true do |t|
      t.column :title, :string
      t.column :link, :string
      t.column :guid, :string
      t.column :description, :string
      t.column :content, :string
      t.column :creator, :string
      t.column :pubdate, :datetime
    end
  end

  def self.down
    drop_table :entries
  end
end
