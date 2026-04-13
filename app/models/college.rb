class College < ApplicationRecord
  DEFAULT_MAX_ITEMS_PER_USER = 30
  DEFAULT_MAX_ITEM_PRICE_HKD = Item::MAX_PRICE_HKD

  has_many :users
  has_many :items

  before_validation :assign_slug

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  validates :max_items_per_user, numericality: { only_integer: true, greater_than: 0 }
  validates :max_item_price, numericality: {
    greater_than: 0,
    less_than_or_equal_to: Item::MAX_PRICE_HKD
  }

  def posting_limit_reached_by?(user)
    user.present? && user.live_items_count >= max_items_per_user
  end

  def default_location_key
    LocationService.default_location_key_for_college(self)
  end

  private

  def assign_slug
    return unless has_attribute?(:slug)
    return if self[:slug].present? || name.blank?

    self.slug = name.to_s.parameterize
  end
end
