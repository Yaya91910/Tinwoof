class Dog < ApplicationRecord
  GENDERS = %w[female male].freeze
  TRAITS = %w[playful calm sporty cuddly sociable curious shy protective].freeze
  MAX_TRAITS = 4
  MAX_PHOTOS = 6

  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :swipes, dependent: :destroy
  has_many_attached :photos

  geocoded_by :address

  before_validation :normalize_traits
  after_validation :geocode, if: :needs_geocoding?

  validates :name, :breed, presence: true
  validates :gender, inclusion: { in: GENDERS }
  validates :age, numericality: { only_integer: true, in: 0..30 }, allow_nil: true
  validates :height_cm, numericality: { only_integer: true, in: 5..120 }, allow_nil: true
  validates :description, length: { maximum: 600 }
  validate :traits_are_known
  validate :photos_are_images

  scope :newest_first, -> { order(created_at: :desc) }
  scope :not_owned_by, ->(user) { where.not(user: user) }
  scope :unswiped_by, ->(user) { where.not(id: user.swipes.select(:dog_id)) }
  scope :with_gender, ->(gender) { GENDERS.include?(gender) ? where(gender: gender) : all }

  # Dogs around the user, closest first (each record exposes `distance` in km).
  # Without a known position we fall back to the newest geocoded dogs.
  def self.around(user, radius_km: user.search_radius_km)
    return geocoded.newest_first unless user.located?

    near(user.coordinates, radius_km, units: :km)
  end

  def female?
    gender == "female"
  end

  def owned_by?(other)
    other.present? && user_id == other.id
  end

  def cover_photo
    photos.first
  end

  private

  # Coordinates picked through the address autocomplete win over server-side geocoding.
  def needs_geocoding?
    address.present? && will_save_change_to_address? && !coordinates_provided?
  end

  def coordinates_provided?
    latitude.present? && longitude.present? &&
      (will_save_change_to_latitude? || will_save_change_to_longitude?)
  end

  def normalize_traits
    self.traits = Array(traits).compact_blank.map(&:to_s).uniq
  end

  def traits_are_known
    errors.add(:traits, :inclusion) if (traits - TRAITS).any?
    errors.add(:traits, :too_long, count: MAX_TRAITS) if traits.size > MAX_TRAITS
  end

  def photos_are_images
    errors.add(:photos, :too_long, count: MAX_PHOTOS) if photos.size > MAX_PHOTOS
    errors.add(:photos, :invalid) if photos.any? { |photo| !photo.content_type.to_s.start_with?("image/") }
  end
end
