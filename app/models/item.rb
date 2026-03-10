class Item < ApplicationRecord
  belongs_to :user
  belongs_to :college
  belongs_to :category, optional: true

  # We can add validations later to make sure items always have a title and price!
  validates :title, :price, presence: true
  validates :price, numericality: { greater_than: 0 }

  # Add this scope so Ben's controller knows how to find available items!
  scope :available, -> { where(status: "available") }

  # fuzzy search
  include PgSearch::Model

  DICTIONARY = 'simple' 
  pg_search_scope :intelligent_search,
    against: {
      title: 'A',
      description: 'C'
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
      },
      dmetaphone: {}      # optional English phonetic search
    },
    ignoring: :accents
end