class Message < ApplicationRecord
  belongs_to :chat

  enum :role, { system: 0, user: 10 }
end
