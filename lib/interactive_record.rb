require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
  
  def self.table_name 
    self.to_s.downcase.pluralize
  end 
  
  def self.column_names 
    DB[:conn].results_as_hash = true
    sql = "PRAGMA table_info ('#{table_name}')"
    column_names = DB[:conn].execute(sql).map do |column|
      column["name"]
    end.compact
  end 
  
  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end 
  end
  
  def table_name_for_insert 
    self.class.table_name
  end 
  
  def col_names_for_insert 
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end 
  
  def values_for_insert 
    self.class.column_names.map do |col_name|
      "'#{send(col_name)}'" unless send(col_name).nil? 
    end.compact.join(", ")
  end
  
  def save 
    sql = <<-SQL 
      INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})
    SQL
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end 
  
  def self.find_by_name(name)
    sql = <<-SQL
      SELECT * FROM #{table_name} WHERE name = ?
    SQL
    DB[:conn].execute(sql, name)
  end 
  
  def self.find_by(hash)
    sql = <<-SQL
      SELECT * FROM #{table_name} WHERE #{hash.keys.join} = ?
    SQL
    DB[:conn].execute(sql, hash.values.join)
  end 

end