require 'rbnacl'

module Users
  class PasswordsDontMatchError < StandardError
  end

  class PasswordTooShortError < StandardError
  end

  class UserAlreadyExists < SQLite3::ConstraintException
  end

  class Store
    def initialize(db)
      @db = db
    end

    def create(name, email: nil)
      id = @db.get_first_value('INSERT INTO users (name, email) VALUES (?, ?) RETURNING (id)', name, email)
      User.new(id, name, email)
    end

    def fetch_by_name(name)
      row = @db.get_first_row('SELECT id, name, email FROM users WHERE name = ?', name)
      if !row
        nil
      else
        id, name, email = row
        User.new(id, name, email)
      end
    end

    def fetch_by_id(user_id)
      row = @db.get_first_row('SELECT id, name, email FROM users WHERE id = ?', user_id)
      if !row
        nil
      else
        id, name, email = row
        User.new(id, name, email)
      end
    end

    def set_password!(user, password, verify)
      # TODO: do we need constant time verification here
      raise PasswordsDontMatchError, "passwords don't match" if password != verify
      raise PasswordTooShortError, 'password is too short' if password.length < 8

      digest = RbNaCl::PasswordHash.argon2_str(password)
      @db.execute('UPDATE users SET password_digest = ? WHERE id = ?', digest, user.id)
    end

    def password_valid?(user, password)
      digest = @db.get_first_value('SELECT password_digest FROM users WHERE id = ?', user.id)
      RbNaCl::PasswordHash.argon2_valid?(password, digest)
    end

    User = Struct.new(:id, :name, :email)
  end
end
