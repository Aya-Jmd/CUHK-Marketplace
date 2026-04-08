class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  # Roles engine
  enum :role, { student: 0, admin: 1, college_admin: 2 }

  belongs_to :college, optional: true
  belongs_to :banned_by, class_name: "User", optional: true
  has_many :items
  has_many :item_reports, foreign_key: :reporter_id, inverse_of: :reporter
  has_many :messages
  has_many :conversations_as_buyer, class_name: "Conversation", foreign_key: "buyer_id"
  has_many :conversations_as_seller, class_name: "Conversation", foreign_key: "seller_id"
  has_many :offers_made, class_name: "Offer", foreign_key: "buyer_id"
  has_many :offers_received, class_name: "Offer", foreign_key: "seller_id"
  has_many :notifications, foreign_key: :recipient_id, dependent: :destroy

  validates :college, presence: true, unless: :admin?

  scope :active, -> { where(banned_at: nil) }
  scope :banned, -> { where.not(banned_at: nil) }

  def banned?
    banned_at.present?
  end

  def ban!(actor:)
    update!(banned_at: Time.current, banned_by: actor)
  end

  def unban!
    update!(banned_at: nil, banned_by: nil)
  end

  def active_for_authentication?
    super && !banned?
  end

  def inactive_message
    banned? ? :locked : super
  end

  def display_name
    email.to_s.split("@").first
  end

  # Location methods
  def has_location?
    latitude.present? && longitude.present?
  end

  def location_display_name
    return "Location not set" unless default_location.present?
    default_location.split("_").map(&:capitalize).join(" ")
  end

  def set_location(location_key)
    coords = LocationService.get_coordinates(location_key)
    if coords
      self.latitude = coords[:lat]
      self.longitude = coords[:lng]
      self.default_location = location_key
      save
    end
  end

  def location_coordinates
    return nil unless has_location?
    { lat: latitude, lng: longitude }
  end
end
