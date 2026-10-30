class SwipesController < ApplicationController
  def create
    dog = Dog.not_owned_by(current_user).find(params.require(:dog_id))
    liked = ActiveModel::Type::Boolean.new.cast(params.fetch(:liked))
    chatroom = Swipe.record!(user: current_user, dog: dog, liked: liked)

    render json: { match: chatroom.present?, chatroom_url: chatroom && chatroom_path(chatroom) }
  end
end
