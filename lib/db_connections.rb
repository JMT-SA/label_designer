class DBConnections
  def db
    @connection ||= make_connection
    @connection
  end

  def make_connection
    Sequel.connect('postgres://postgres:postgres@localhost/label_designer')
  end

  def base(key = :default)
    db
  end

end
