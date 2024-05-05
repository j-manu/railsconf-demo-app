class Message < ApplicationRecord
  belongs_to :chat

  enum :role, { system: 0, user: 10 }

  scope :latest_last, -> { order(created_at: :asc) }
end
