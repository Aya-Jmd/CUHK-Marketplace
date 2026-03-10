class Item < ApplicationRecord
  belongs_to :user
  belongs_to :college

  # We can add validations later to make sure items always have a title and price!

  # fuzzy search
  include PgSearch::Model

  DICTIONARY = 'simple' 
  pg_search_scope :intelligent_search,
    against: {
      title: 'A',
      category: 'B',
      description: 'C'
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