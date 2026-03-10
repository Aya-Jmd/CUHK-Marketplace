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

puts "Done! #{College.count} colleges are now in the database."
