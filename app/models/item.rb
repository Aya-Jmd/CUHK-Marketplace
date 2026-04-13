class Item < ApplicationRecord
  MAX_PRICE_HKD = 9_999_999
  MAX_TITLE_LENGTH = 100
  MAX_DESCRIPTION_LENGTH = 1000

  belongs_to :user
  belongs_to :college
  belongs_to :category, optional: true
  has_many :offers, dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_many :item_reports, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :notifications, as: :notifiable, dependent: :destroy
  has_many :favorited_by_users, through: :favorites, source: :user

  has_many_attached :images

  validates :title, :price, presence: true
  validates :title, length: { maximum: MAX_TITLE_LENGTH }
  validates :description, length: { maximum: MAX_DESCRIPTION_LENGTH }
  validates :price, numericality: {
    greater_than: 0,
    less_than_or_equal_to: MAX_PRICE_HKD
  }
  validate :price_within_college_limit

  scope :available, -> { joins(:user).merge(User.active).where(status: "available") }

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
        prefix: true,
        any_word: true
      },
      trigram: {
        threshold: 0.2
      }
    },
    ignoring: :accents

  def has_location?
    latitude.present? && longitude.present?
  end

  def location_display_name
    return "Location not specified" unless location_name.present?

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

  def walking_distance_from(user_location)
    return nil unless user_location && has_location?
    return nil unless user_location[:lat] && user_location[:lng]

    LocationService.calculate_walking_distance(
      user_location[:lat], user_location[:lng],
      latitude, longitude
    )
  end

  def self.nearby(lat, lng, radius_km = 2)
    where.not(latitude: nil, longitude: nil).select do |item|
      distance = LocationService.calculate_distance(lat, lng, item.latitude, item.longitude)
      distance <= radius_km
    end
  end

  def removed?
    status == "removed"
  end

  def reserved_for_transaction?
    status == "pending_dropoff"
  end

  def active_transaction_offer
    return @active_transaction_offer if defined?(@active_transaction_offer)

    @active_transaction_offer =
      if reserved_for_transaction?
        offers.accepted.includes(:buyer).order(updated_at: :desc).first
      end
  end

  def reserved_transaction_buyer
    active_transaction_offer&.buyer
  end

  def visible_to?(viewer)
    return reserved_viewable_by?(viewer) if reserved_for_transaction?
    return true if viewer == user
    return true if viewer&.admin?
    return true if viewer&.college_admin? && viewer.college_id == college_id

    return false if removed? || user&.banned?
    return is_global? if viewer.blank? || viewer.college_id.blank?

    is_global? || viewer.college_id == college_id
  end

  def reserved_viewable_by?(viewer)
    return true if viewer == user
    return true if viewer == reserved_transaction_buyer
    return true if viewer&.admin?
    return true if viewer&.college_admin? && viewer.college_id == college_id

    false
  end

  def college_max_price_hkd
    college&.max_item_price || MAX_PRICE_HKD
  end

  def college_price_limit_exceeded?
    price.present? && price.to_d > college_max_price_hkd.to_d
  end

  private

  def price_within_college_limit
    return unless college_price_limit_exceeded?

    errors.add(:price, "must be less than or equal to #{college_max_price_hkd}")
  end
end
