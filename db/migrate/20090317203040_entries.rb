class Entries < ActiveRecord::Migration
  def self.up
    create_table :entries, :force => true do |t|
      t.column :date, :date
      t.column :header, :string
      t.column :body, :string
      t.column :footer, :string
      t.column :permalink, :string
    end
  end

  def self.down
    drop_table :entries
  end
end
