class Swipe < ApplicationRecord
  belongs_to :user
  belongs_to :dog

  validates :liked, inclusion: { in: [true, false] }
  validates :dog_id, uniqueness: { scope: :user_id }
  validate :cannot_swipe_own_dog

  scope :likes, -> { where(liked: true) }

  # Records a like/pass and returns the chatroom when the like completes a mutual match.
  def self.record!(user:, dog:, liked:)
    swipe = find_or_initialize_by(user: user, dog: dog)
    swipe.update!(liked: liked)
    Chatroom.between(user, dog.user) if swipe.mutual?
  end

  # A like is mutual once the dog's owner has liked one of this user's dogs.
  def mutual?
    liked? && Swipe.likes.joins(:dog).exists?(user_id: dog.user_id, dogs: { user_id: user_id })
  end

  private

  def cannot_swipe_own_dog
    errors.add(:dog, :invalid) if dog&.owned_by?(user)
  end
end
