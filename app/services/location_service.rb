class LocationService
  CUHK_LOCATIONS = {
    "shaw" => { name: "Shaw College", lat: 22.4179, lng: 114.2065 },
    "new_asia" => { name: "New Asia College", lat: 22.4188, lng: 114.2078 },
    "united" => { name: "United College", lat: 22.4181, lng: 114.2092 },
    "wu_yee_sun" => { name: "Wu Yee Sun College", lat: 22.4155, lng: 114.2110 },
    "chung_chi" => { name: "Chung Chi College", lat: 22.4162, lng: 114.2085 },
    "campus_central" => { name: "Central Campus", lat: 22.4172, lng: 114.2071 },
    "library" => { name: "University Library", lat: 22.4180, lng: 114.2068 },
    "sir_run_run_shaw_hall" => { name: "Sir Run Run Shaw Hall", lat: 22.4185, lng: 114.2062 },
    "lecture_theatres" => { name: "Lecture Theatres Complex", lat: 22.4175, lng: 114.2080 }
  }

  def self.get_coordinates(location_key)
    location = CUHK_LOCATIONS[location_key.to_s.downcase]
    return { lat: location[:lat], lng: location[:lng], name: location[:name] } if location
    nil
  end

  def self.calculate_distance(lat1, lon1, lat2, lon2)
    return 0 if lat1.nil? || lon1.nil? || lat2.nil? || lon2.nil?

    # Haversine formula
    rad_per_deg = Math::PI / 180
    earth_radius_km = 6371

    dlat_rad = (lat2 - lat1) * rad_per_deg
    dlon_rad = (lon2 - lon1) * rad_per_deg

    a = Math.sin(dlat_rad / 2) ** 2 +
        Math.cos(lat1 * rad_per_deg) *
        Math.cos(lat2 * rad_per_deg) *
        Math.sin(dlon_rad / 2) ** 2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

    (earth_radius_km * c).round(2)
  end

  def self.location_options
    CUHK_LOCATIONS.map { |key, value| [ value[:name], key ] }
  end
end
