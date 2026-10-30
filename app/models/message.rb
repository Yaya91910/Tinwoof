class Message < ApplicationRecord
  belongs_to :chatroom, touch: :last_message_at
  belongs_to :user

  validates :content, presence: true, length: { maximum: 2000 }
  validate :author_is_participant

  scope :unread, -> { where(read_at: nil) }

  after_create_commit :broadcast_to_participants

  def recipient
    chatroom.interlocutor_of(user)
  end

  private

  def author_is_participant
    errors.add(:user, :invalid) unless chatroom&.participant?(user)
  end

  def broadcast_to_participants
    broadcast_append_to chatroom, target: "messages", partial: "messages/message", locals: { message: self }
    broadcast_replace_to [recipient, :inbox],
                         target: "unread_badge",
                         partial: "shared/unread_badge",
                         locals: { count: recipient.unread_messages_count }
  end
end
