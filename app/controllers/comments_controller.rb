class CommentsController < ApplicationController
  def create
    @dog = Dog.find(params[:dog_id])
    @comment = @dog.comments.new(comment_params.merge(user: current_user))

    respond_to do |format|
      if @comment.save
        format.turbo_stream
        format.html { redirect_to dog_path(@dog, anchor: "comments") }
      else
        format.turbo_stream { render :create, status: :unprocessable_entity }
        format.html { redirect_to dog_path(@dog, anchor: "comments"), alert: @comment.errors.full_messages.to_sentence }
      end
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:content)
  end
end
