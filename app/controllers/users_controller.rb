class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
    return redirect_to(profile_path) if @user == current_user

    @dogs = @user.dogs.with_attached_photos.newest_first
  end
end
