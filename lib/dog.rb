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

  # This delets our table
  def self.drop_table
    sql = <<-SQL
      DROP TABLE dogs;
    SQL

    DB[:conn].execute(sql)
  end

  # The '.save' method basically saves our object instance
  # into our dogs table. If however the id of the instance
  # thats using the method exists it updates itself instead.
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

  # The '.find_or_create_by' method finds or creates
  # our passed arguments. If arguments don't exist
  # in both the name and breed from our dogs
  # table this method will create an object instance and
  # save the data inside our table and return that obj instance.
  # If they do exist the method just creates and instance of that
  # row and returns it.
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

  # '.create' is a helper method that creates our obj instances
  # and saves it into our database.
  def self.create(name:, breed:)
    new_obj = self.new(name: name, breed: breed)
    new_obj.save
    new_obj
  end

  # '.new_from_db' is a helper method that takes an
  # array, equivalent to values in a table's row, and
  # creates object instances from that array.
  def self.new_from_db(row)
    self.new(id: row[0], name: row[1], breed: row[2])
  end

  # '.find_by_name' finds if that name exists and
  # returns instance objects of the rows with the
  # similar name.
  def self.find_by_name(name)
    sql = <<-SQL
      SELECT * FROM dogs
      WHERE name = ?;
    SQL

    data = DB[:conn].execute(sql, name)

    data.map do |row|
      self.new_from_db(row)
    end.first
  end

  # '.update' just updates the table if the values inside
  # an instance object is changed.
  def update
    sql = <<-SQL
      UPDATE dogs
      SET name = ?, breed = ?
      WHERE id = ?;
    SQL

    DB[:conn].execute(sql, self.name, self.breed, self.id)
  end

  # '.find_by_id' similar to the '.find_by_name' method
  # instead this uses the id attribute to find a specific
  # row. This method will return an instance of that table.
  def self.find_by_id(id)
    sql = <<-SQL
      SELECT * FROM dogs
      WHERE id = ?;
    SQL

    self.new_from_db(DB[:conn].execute(sql, id).flatten)
  end
end
