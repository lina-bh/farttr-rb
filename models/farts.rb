# frozen_string_literal: true

module Farts
  class Store
    def initialize(db)
      @db = db
    end

    def create(user, time: nil)
      time ||= Time.now.to_i
      @db.get_first_value('INSERT INTO farts (user, time) VALUES (?, ?) RETURNING (id)', user.id, time)
      Fart.new(id, user.id, time)
    end

    Fart = Struct.new(:id, :user_id, :time)
  end
end
