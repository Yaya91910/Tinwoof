class Swipe < ApplicationRecord
  SUPERLIKES_PER_DAY = 3

  belongs_to :user
  belongs_to :dog

  validates :liked, inclusion: { in: [true, false] }
  validates :dog_id, uniqueness: { scope: :user_id }
  validate :cannot_swipe_own_dog
  validate :superlike_is_a_like
  validate :superlike_quota, if: -> { superlike? && will_save_change_to_superlike? }

  scope :likes, -> { where(liked: true) }
  scope :superlikes, -> { where(superlike: true) }
  scope :today, -> { where(updated_at: Time.current.all_day) }

  # Records a decision and returns the chatroom when the like completes a mutual match.
  def self.record!(user:, dog:, liked:, superlike: false)
    swipe = find_or_initialize_by(user: user, dog: dog)
    swipe.update!(liked: liked, superlike: liked && superlike)
    return unless swipe.mutual?

    Chatroom.between(user, dog.user).tap { |chatroom| swipe.announce_match(chatroom) }
  end

  # Takes back the user's latest decision, unless it already led to a match.
  def self.undo_last!(user)
    swipe = user.swipes.order(updated_at: :desc).first
    return if swipe.nil? || swipe.mutual?

    swipe.destroy!
  end

  # A like is mutual once the dog's owner has liked one of this user's dogs.
  def mutual?
    liked? && Swipe.likes.joins(:dog).exists?(user_id: dog.user_id, dogs: { user_id: user_id })
  end

  # The other owner learns about the match live, wherever they are in the app.
  def announce_match(chatroom)
    Turbo::StreamsChannel.broadcast_append_to [dog.user, :inbox],
                                              target: "toasts",
                                              partial: "shared/live_toast",
                                              locals: { text: "C'est un match avec #{user.first_name} ! 🎉",
                                                        url: Rails.application.routes.url_helpers.chatroom_path(chatroom),
                                                        icon: "heart" }
  end

  private

  def cannot_swipe_own_dog
    errors.add(:dog, :invalid) if dog&.owned_by?(user)
  end

  def superlike_is_a_like
    errors.add(:superlike, :invalid) if superlike? && !liked?
  end

  def superlike_quota
    errors.add(:superlike, :exhausted) if user && user.superlikes_left_today <= 0
  end
end
