module DogsHelper
  def dog_photo_url(dog, width: 600, height: (width * 4 / 3))
    photo_url(dog.cover_photo, width: width, height: height)
  end

  def gender_label(dog)
    t("dogs.genders.#{dog.gender}", default: dog.gender.to_s.humanize)
  end

  def gender_icon(dog)
    icon(dog.female? ? "venus" : "mars", class: "gender gender--#{dog.gender}", title: gender_label(dog))
  end

  def trait_label(trait)
    t("dogs.traits.#{trait}", default: trait.to_s.humanize)
  end

  def dog_age_label(dog)
    return if dog.age.nil?
    return "Chiot" if dog.age.zero?

    pluralize(dog.age, "an", plural: "ans")
  end

  # Distance from the signed-in user: from the SQL `near` query when available, computed otherwise.
  def dog_distance_km(dog)
    return dog.distance if dog.has_attribute?(:distance)
    return unless current_user&.located? && dog.geocoded?

    dog.distance_to(current_user.coordinates, :km)
  end

  def distance_label(km)
    return if km.nil?

    km = km.to_f
    if km < 1
      t("distance.meters", value: [(km * 1000).round(-1).to_i, 50].max)
    elsif km < 10
      t("distance.kilometers", value: number_with_precision(km, precision: 1, strip_insignificant_zeros: true))
    else
      t("distance.kilometers", value: km.round)
    end
  end

  def directions_url(dog)
    "https://www.google.com/maps/dir/?api=1&destination=#{dog.latitude},#{dog.longitude}&travelmode=walking"
  end
end
