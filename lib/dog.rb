require 'pry'

class Dog
  attr_accessor :id, :name, :breed

  # We are passing our initial values using the keyword argument
  # its basicall like passing a hash as a parameter but it's better
  # cause it specifies which value belongs to which key.
  def initialize(id: nil, name:, breed:)
    self.id = id
    self.name = name
    self.breed = breed
  end

  # This creates our SQL table with 3 columns
  # id increments as soon as we insert a row inside the table
  # name will be mapped with our name attribute in our dog object
  # breed will be mapped with our name attribute in our dog object
  def self.create_table
    sql = <<-SQL
      CREATE TABLE IF NOT EXISTS dogs (
        id INTEGER PRIMARY KEY,
        name TEXT,
        breed TEXT
      );
    SQL

    DB[:conn].execute(sql)
  end

  def self.drop_table
    sql = <<-SQL
      DROP TABLE dogs;
    SQL

    DB[:conn].execute(sql)
  end

  def save
    if self.id != nil
      self.update
    else
      sql = <<-SQL
        INSERT INTO dogs (name, breed)
        VALUES (?, ?);
      SQL

      DB[:conn].execute(sql, self.name, self.breed)
      @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs;")[0][0]

      self
    end
  end

  def self.find_or_create_by(name:, breed:)
    sql = <<-SQL
      SELECT * FROM dogs
      WHERE name = ? AND breed = ?;
    SQL

    data = DB[:conn].execute(sql, name, breed).flatten

    if data.empty?
      dog = self.create(name: name, breed: breed)
    else
      dog_data = data[0]
      dog = self.new(id: dog_data[0], name: dog_data[1], breed: dog_data[2])
    end
    dog
  end

  def self.create(name:, breed:)
    new_obj = self.new(name: name, breed: breed)
    new_obj.save
    new_obj
  end

  def self.new_from_db(row)
    self.new(id: row[0], name: row[1], breed: row[2])
  end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT * FROM dogs
      WHERE name = ?;
    SQL

    self.new_from_db(DB[:conn].execute(sql, name).flatten)
  end

  def update
    sql = <<-SQL
      UPDATE dogs
      SET name = ?, breed = ?
      WHERE id = ?;
    SQL

    DB[:conn].execute(sql, self.name, self.breed, self.id)
  end

  def self.find_by_id(id)
    sql = <<-SQL
      SELECT * FROM dogs
      WHERE id = ?;
    SQL

    self.new_from_db(DB[:conn].execute(sql, id).flatten)
  end
end
