class DiscoverController < ApplicationController
  DECK_SIZE = 20

  def show
    @dogs = Dog.around(current_user)
               .not_owned_by(current_user)
               .unswiped_by(current_user)
               .includes(:user)
               .with_attached_photos
               .limit(DECK_SIZE)
               .to_a
  end
end
