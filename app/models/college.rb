class College < ApplicationRecord
  has_many :users
  has_many :items

  before_validation :assign_slug

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  private

  def assign_slug
    return unless has_attribute?(:slug)
    return if self[:slug].present? || name.blank?

    self.slug = name.to_s.parameterize
  end
end
