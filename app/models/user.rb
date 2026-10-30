class User < ApplicationRecord
  ONLINE_WINDOW = 5.minutes
  SEARCH_RADII_KM = [2, 5, 10, 25, 50, 100].freeze
  # 3 decimals ≈ 110 m: precise enough for distances, too coarse to reveal a home address.
  LOCATION_PRECISION = 3

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :dogs, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :swipes, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_one_attached :photo

  reverse_geocoded_by :latitude, :longitude

  # Chatrooms reference both participants, so they must go before the user does.
  before_destroy :destroy_chatrooms, prepend: true

  validates :first_name, :last_name, presence: true
  validates :bio, length: { maximum: 300 }
  validates :search_radius_km, inclusion: { in: SEARCH_RADII_KM }
  validates :latitude, numericality: { in: -90..90 }, allow_nil: true
  validates :longitude, numericality: { in: -180..180 }, allow_nil: true

  scope :online, -> { where(last_seen_at: ONLINE_WINDOW.ago..) }

  def chatrooms
    Chatroom.involving(self)
  end

  def full_name
    [first_name, last_name].compact_blank.map { |name| name.strip.upcase_first }.join(" ")
  end

  def located?
    latitude.present? && longitude.present?
  end

  def coordinates
    [latitude, longitude] if located?
  end

  def online?
    last_seen_at.present? && last_seen_at > ONLINE_WINDOW.ago
  end

  def update_location(latitude:, longitude:, label: nil)
    lat = Float(latitude, exception: false)
    lng = Float(longitude, exception: false)
    return false if lat.nil? || lng.nil?

    update(
      latitude: lat.round(LOCATION_PRECISION),
      longitude: lng.round(LOCATION_PRECISION),
      address: label.presence || address,
      located_at: Time.current
    )
  end

  def forget_location!
    update!(latitude: nil, longitude: nil, located_at: nil)
  end

  def unread_messages_count
    Message.unread.where(chatroom_id: chatrooms.select(:id)).where.not(user: self).count
  end

  private

  def destroy_chatrooms
    chatrooms.destroy_all
  end
end
