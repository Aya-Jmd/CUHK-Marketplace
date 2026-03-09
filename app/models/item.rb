class Item < ApplicationRecord
  belongs_to :user
  belongs_to :college

  # We can add validations later to make sure items always have a title and price!
end