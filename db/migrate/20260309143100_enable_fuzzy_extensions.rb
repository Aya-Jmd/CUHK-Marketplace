class EnableFuzzyExtensions < ActiveRecord::Migration[7.0]
  def change
    enable_extension 'unaccent'
    enable_extension 'fuzzystrmatch'
  end
end
