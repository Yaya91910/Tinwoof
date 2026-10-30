class ProfilesController < ApplicationController
  def show
    @user = current_user
    @dogs = @user.dogs.with_attached_photos.newest_first
    @received_comments = Comment.joins(:dog).where(dogs: { user_id: @user.id })
                                .includes(:dog, user: { photo_attachment: :blob })
                                .newest_first.limit(20)
    @likes_count = Swipe.likes.joins(:dog).where(dogs: { user_id: @user.id }).count
    @matches_count = @user.chatrooms.count
    # Admirers we have not liked back yet: one like from us and it's a match.
    liked_owner_ids = @user.swipes.likes.joins(:dog).pluck("dogs.user_id")
    @admirer_likes = @user.admirer_likes.values.reject { |like| liked_owner_ids.include?(like.user_id) }
    @admirers = User.where(id: @admirer_likes.map(&:user_id)).with_attached_photo.index_by(&:id)
  end

  def update
    if current_user.update(profile_params)
      redirect_to (params[:return_to] == "discover" ? root_path : profile_path), notice: t(".updated"), status: :see_other
    else
      redirect_to profile_path, alert: current_user.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private

  def profile_params
    params.require(:user).permit(:search_radius_km, :bio)
  end
end
