class Item < ApplicationRecord
  belongs_to :user
  belongs_to :college
  belongs_to :category, optional: true
  has_many :offers, dependent: :destroy

  has_many_attached :images

  # We can add validations later to make sure items always have a title and price!
  validates :title, :price, presence: true
  validates :price, numericality: { greater_than: 0 }

  # Add this scope so Ben's controller knows how to find available items!
  scope :available, -> { where(status: "available") }

  # fuzzy search
  include PgSearch::Model

  DICTIONARY = "simple"
  pg_search_scope :intelligent_search,
    against: {
      title: "A",
      description: "C"
    },
    associated_against: {
      category: :name
    },
    using: {
      tsearch: {
        dictionary: DICTIONARY,
        prefix: true,     # "calc" => "calculus"
        any_word: true
      },
      trigram: {
        threshold: 0.2    # typo tolerance: lower threshold => fuzzier
      }
    },
    ignoring: :accents


    # Location feature

    def has_location?
    latitude.present? && longitude.present?
  end

  def location_display_name
    return "Location not specified" unless location_name.present?
    # Convert "shaw" to "Shaw College", "new_asia" to "New Asia College", etc.
    location_name.split("_").map(&:capitalize).join(" ")
  end

  def distance_from(user_location)
    return nil unless user_location && has_location?
    return nil unless user_location[:lat] && user_location[:lng]

    LocationService.calculate_distance(
      user_location[:lat], user_location[:lng],
      latitude, longitude
    )
  end

  # Class method to find nearby items
  def self.nearby(lat, lng, radius_km = 2)
    where.not(latitude: nil, longitude: nil).select do |item|
      distance = LocationService.calculate_distance(lat, lng, item.latitude, item.longitude)
      distance <= radius_km
    end
  end
end
