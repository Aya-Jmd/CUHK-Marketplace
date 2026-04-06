class College < ApplicationRecord
  has_many :users
  has_many :items

  validates :name, presence: true, uniqueness: true
end
