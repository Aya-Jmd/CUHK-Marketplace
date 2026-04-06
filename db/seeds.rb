# ------- COLLEGE TABLE SEEDS

puts "Creating CUHK Colleges..."

colleges = [
  "Chung Chi College",
  "New Asia College",
  "United College",
  "Shaw College",
  "Morningside College",
  "S.H. Ho College",
  "C.W. Chu College",
  "Wu Yee Sun College",
  "Lee Woo Sing College"
]

colleges.each do |college_name|
  College.find_or_create_by!(name: college_name, listing_expiry_days: 30)
end

puts "Done! #{College.count} colleges are now in the database."



# ------- CATEGORY TABLE SEEDS

puts "Creating item categories..."


categories = [
  "Textbook",
  "Book",
  "Electronic",
  "Food",
  "Clothing",
  "Other"
]

categories.each do |category_name|
  Category.find_or_create_by!(name: category_name)
end

puts "Done! #{Category.count} categories are now in the database."



# ------- CURRENCY TABLE SEEDS

puts "Creating currency tables..."

Currency.find_or_create_by!(code: "HKD") do |c|
  c.name  = "HK Dollar"
  c.symbol = "HK$"
  c.rate_from_hkd = 1.0 # because data in DB is stored in HKD
end

Currency.find_or_create_by!(code: "USD") do |c|
  c.name  = "US Dollar"
  c.symbol = "US$"
  c.rate_from_hkd = 0.127
end

Currency.find_or_create_by!(code: "EUR") do |c|
  c.name  = "Euros"
  c.symbol = "€"
  c.rate_from_hkd = 0.110
end

puts "Done! #{Currency.count} currencies are now in the database."
