class Category < ApplicationRecord
  has_many :items, dependent: :nullify
  validates :name, presence: true, uniqueness: true

  def self.sorted_for_dropdown
    return none unless table_exists?

    all.sort_by { |category| [ category.name == "Other" ? 1 : 0, category.name ] }
  end
end
