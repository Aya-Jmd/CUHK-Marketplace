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