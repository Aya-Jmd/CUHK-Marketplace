class Api::LocationsController < ApplicationController
  def show
    location = LocationService.get_coordinates(params[:key])
    if location
      render json: { lat: location[:lat], lng: location[:lng], name: location[:name] }
    else
      render json: { error: "Location not found" }, status: :not_found
    end
  end

  def closest
    lat = params[:lat].to_f
    lng = params[:lng].to_f

    closest = nil
    min_distance = Float::INFINITY

    LocationService::CUHK_LOCATIONS.each do |key, location|
      distance = LocationService.calculate_distance(lat, lng, location[:lat], location[:lng])
      if distance < min_distance
        min_distance = distance
        closest = key
      end
    end

    if closest
      render json: { key: closest, name: LocationService::CUHK_LOCATIONS[closest][:name], distance: min_distance }
    else
      render json: { error: "No location found" }, status: :not_found
    end
  end

  def all
    locations = LocationService::CUHK_LOCATIONS.map do |key, value|
      {
        key: key,
        name: value[:name],
        lat: value[:lat],
        lng: value[:lng]
      }
    end
    render json: locations
  end
end
