class LocationsController < ApplicationController
  def update
    located = current_user.update_location(
      latitude: location_params[:latitude],
      longitude: location_params[:longitude],
      label: location_params[:label]
    )

    head(located ? :no_content : :unprocessable_entity)
  end

  def destroy
    current_user.forget_location!
    redirect_to profile_path, notice: t(".forgotten"), status: :see_other
  end

  private

  def location_params
    params.require(:location).permit(:latitude, :longitude, :label)
  end
end
