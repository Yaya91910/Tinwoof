class Chatroom < ApplicationRecord
  belongs_to :first_user, class_name: "User"
  belongs_to :second_user, class_name: "User"
  has_many :messages, -> { order(:created_at) }, dependent: :destroy, inverse_of: :chatroom

  validate :participants_are_distinct

  scope :involving, ->(user) { where(first_user: user).or(where(second_user: user)) }
  scope :recent_first, -> { order(Arel.sql("COALESCE(chatrooms.last_message_at, chatrooms.created_at) DESC")) }

  def self.between(user, other)
    find_by(first_user: user, second_user: other) ||
      find_by(first_user: other, second_user: user) ||
      create!(first_user: user, second_user: other)
  end

  def participant?(user)
    user.present? && [first_user_id, second_user_id].include?(user.id)
  end

  def interlocutor_of(user)
    user == first_user ? second_user : first_user
  end

  def last_message
    messages.last
  end

  def unread_count_for(user)
    messages.unread.where.not(user: user).count
  end

  def mark_read_for!(user)
    messages.unread.where.not(user: user).update_all(read_at: Time.current)
  end

  private

  def participants_are_distinct
    errors.add(:second_user, :invalid) if first_user_id == second_user_id
  end
end
