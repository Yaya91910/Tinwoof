class MessagesController < ApplicationController
  def create
    @chatroom = current_user.chatrooms.find(params[:chatroom_id])
    @message = @chatroom.messages.new(message_params.merge(user: current_user))

    respond_to do |format|
      if @message.save
        # The message itself reaches both participants through the Turbo Stream broadcast.
        format.turbo_stream { @message = Message.new }
        format.html { redirect_to @chatroom }
      else
        format.turbo_stream { render :create, status: :unprocessable_entity }
        format.html { redirect_to @chatroom, alert: @message.errors.full_messages.to_sentence }
      end
    end
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end
end
