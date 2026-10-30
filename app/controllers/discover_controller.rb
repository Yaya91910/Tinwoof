class DiscoverController < ApplicationController
  DECK_SIZE = 20
  ADMIRERS_IN_DECK = 10

  def show
    @admirer_likes = current_user.admirer_likes
    nearby = deck_scope(Dog.around(current_user)).limit(DECK_SIZE).to_a
    admired_by = deck_scope(Dog.where(user_id: @admirer_likes.keys)).limit(ADMIRERS_IN_DECK).to_a

    # Dogs whose owner already liked us come first: super likes, then likes, then the closest.
    @dogs = (admired_by + nearby).uniq(&:id).each_with_index.sort_by do |dog, index|
      like = @admirer_likes[dog.user_id]
      [like.nil? ? 2 : (like.superlike? ? 0 : 1), index]
    end.map(&:first)
    @waiting_admirers = admired_by.map(&:user_id).uniq.size
    @superlikes_left = current_user.superlikes_left_today
  end

  private

  def deck_scope(dogs)
    dogs.not_owned_by(current_user).unswiped_by(current_user).includes(:user).with_attached_photos
  end
end
