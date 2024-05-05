class Chat < ApplicationRecord
  belongs_to :user

  has_many :messages, dependent: :destroy

  after_create_commit do
    Message.create!(chat: self, role: :system, content: "Hello! How can I help you?")
  end
end
