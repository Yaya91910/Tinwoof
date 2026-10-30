class ChatroomsController < ApplicationController
  def index
    @chatrooms = current_user.chatrooms.recent_first
                             .includes(first_user: { photo_attachment: :blob }, second_user: { photo_attachment: :blob })
                             .to_a
    chatroom_ids = @chatrooms.map(&:id)
    @last_messages = Message.where(id: Message.where(chatroom_id: chatroom_ids).group(:chatroom_id).select("MAX(id)"))
                            .index_by(&:chatroom_id)
    @unread_counts = Message.unread.where(chatroom_id: chatroom_ids).where.not(user: current_user)
                            .group(:chatroom_id).count
  end

  def show
    @chatroom = current_user.chatrooms.find(params[:id])
    @chatroom.mark_read_for!(current_user)
    @interlocutor = @chatroom.interlocutor_of(current_user)
    @messages = @chatroom.messages.includes(:user)
    @message = Message.new
  end

  def read
    current_user.chatrooms.find(params[:id]).mark_read_for!(current_user)
    head :no_content
  end

  def create
    other = User.where.not(id: current_user.id).find(params.require(:user_id))
    redirect_to Chatroom.between(current_user, other)
  end
end
