require 'rom-repository'

class UserRepo < ROM::Repository[:users]
  commands :create

  def query(conditions)
    users.where(conditions)
  end
  # A test using Sequel's SQL + first.
  def count_them
    DB.base['SELECT COUNT(*) FROM users'].first
  end

  def index
    users.index
  end
end
