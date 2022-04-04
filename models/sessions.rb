TWO_WEEKS = 60 * 60 * 24 * 14

module Sessions
  class Store
    def initialize(db)
      @db = db
    end

    def create(user)
      @db.get_first_value('INSERT INTO sessions (expires, user) VALUES (?, ?) RETURNING (id)',
                          Time.now.to_i + TWO_WEEKS, user.id)
    end

    def valid?(session_id)
      @db.get_first_value("SELECT 1 FROM sessions WHERE id = ? AND CAST(strftime('%s','now') AS INTEGER) < expires",
                          session_id) == 1
    end

    def invalidate!(session_id)
      @db.execute('DELETE FROM sessions WHERE id = ?', session_id)
    end

    def user_id_for_session(session_id)
      @db.get_first_value('
        SELECT user
        FROM sessions
        WHERE id = ?
        AND CAST(strftime("%s","now") AS INTEGER) < expires', session_id)
    end
  end
end
