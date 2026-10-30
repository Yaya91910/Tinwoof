class MapsController < ApplicationController
  MAX_MARKERS = 500

  def show
    respond_to do |format|
      format.html
      format.json { @dogs = dogs_in_view }
    end
  end

  private

  # bbox follows the GeoJSON convention: "west,south,east,north".
  def dogs_in_view
    dogs = Dog.geocoded.with_attached_photos.limit(MAX_MARKERS)
    west, south, east, north = params[:bbox].to_s.split(",").map { |value| Float(value, exception: false) }
    return dogs if [west, south, east, north].any?(&:nil?)

    dogs.within_bounding_box([south, west, north, east])
  end
end
