class SwipesController < ApplicationController
  def create
    dog = Dog.not_owned_by(current_user).find(params.require(:dog_id))
    liked = ActiveModel::Type::Boolean.new.cast(params.fetch(:liked))
    superlike = ActiveModel::Type::Boolean.new.cast(params[:superlike]) || false
    chatroom = Swipe.record!(user: current_user, dog: dog, liked: liked, superlike: superlike)

    respond_to do |format|
      format.json do
        render json: { match: chatroom.present?, chatroom_url: chatroom && chatroom_path(chatroom),
                       superlikes_left: current_user.superlikes_left_today }
      end
      format.html do
        if chatroom
          redirect_to chatroom, notice: t(".matched", name: dog.user.first_name)
        else
          key = liked ? (superlike ? ".superliked" : ".liked") : ".passed"
          redirect_back_or_to dog, notice: t(key, name: dog.name)
        end
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.json { render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity }
      format.html { redirect_back_or_to dog, alert: e.record.errors.full_messages.to_sentence }
    end
  end

  def undo
    swipe = Swipe.undo_last!(current_user)
    return head(:unprocessable_entity) unless swipe

    render json: { dog_id: swipe.dog_id, superlikes_left: current_user.superlikes_left_today }
  end
end
