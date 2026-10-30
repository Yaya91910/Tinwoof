class DogsController < ApplicationController
  LIST_SIZE = 60

  before_action :set_own_dog, only: %i[edit update destroy]

  def index
    @gender = params[:gender].presence_in(Dog::GENDERS)
    @radius = params[:radius].to_i.presence_in(User::SEARCH_RADII_KM) || current_user.search_radius_km
    @dogs = Dog.around(current_user, radius_km: @radius)
               .not_owned_by(current_user)
               .with_gender(@gender)
               .includes(:user)
               .with_attached_photos
               .limit(LIST_SIZE)
  end

  def show
    @dog = Dog.includes(:user).with_attached_photos.find(params[:id])
    @comments = @dog.comments.newest_first.includes(user: { photo_attachment: :blob })
    @comment = Comment.new
    @swipe = current_user.swipes.find_by(dog: @dog)
  end

  def new
    @dog = current_user.dogs.new
  end

  def create
    @dog = current_user.dogs.new(dog_params)

    if @dog.save
      redirect_to @dog, notice: t(".created", name: @dog.name)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    @dog.assign_attributes(dog_params.except(:photos))
    # Attaching (rather than assigning) keeps the existing photos.
    new_photos = Array(dog_params[:photos]).compact_blank
    @dog.photos.attach(new_photos) if new_photos.any?

    if @dog.save
      @dog.photos.where(id: params.dig(:dog, :remove_photo_ids)).each(&:purge_later)
      redirect_to @dog, notice: t(".updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @dog.destroy
    redirect_to profile_path, notice: t(".destroyed", name: @dog.name), status: :see_other
  end

  private

  def set_own_dog
    @dog = current_user.dogs.find(params[:id])
  end

  def dog_params
    params.require(:dog).permit(:name, :gender, :age, :breed, :height_cm, :description,
                                :address, :latitude, :longitude, traits: [], photos: [])
  end
end
