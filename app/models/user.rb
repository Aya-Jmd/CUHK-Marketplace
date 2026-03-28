class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :college
  has_many :items
  has_many :messages
  has_many :conversations_as_buyer, class_name: "Conversation", foreign_key: "buyer_id"
  has_many :conversations_as_seller, class_name: "Conversation", foreign_key: "seller_id"
  has_many :offers_made, class_name: "Offer", foreign_key: "buyer_id"
  has_many :offers_received, class_name: "Offer", foreign_key: "seller_id"

  # Location methods
  def has_location?
    latitude.present? && longitude.present?
  end

  def location_display_name
    return "Location not set" unless default_location.present?
    default_location.split('_').map(&:capitalize).join(' ')
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
