require 'yaml'

car2go_config = YAML.load_file('car2go-config.yaml')

# This script connects to WMATA's API. Therefore, you need a WMATA api key.
api_key = car2go_config['api_key']
location = car2go_config['location']
api_uri = "https://www.car2go.com/api/v2.1/vehicles?loc=#{location}&oauth_consumer_key=#{api_key}&format=json"

max_distance_km = 1.0 # ~.62 miles
origin_lat = 38.926354
origin_lon = -77.033987

SCHEDULER.every '30s', :first_in => 0  do
  uri = URI("#{api_uri}")
  http = Net::HTTP.new(uri.hostname, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request = Net::HTTP::Get.new(uri.request_uri)
  res = http.request(request)

  vehicles = JSON.parse(res.body)['placemarks']

  car2go_config['points_of_interest'].each do |poi, options|
    count = 0
    vehicles_nearby = Array.new
    markers = Array.new
    vehicles.each do |vehicle|
      distance = coorDist(options['latitude'], options['longitude'], vehicle['coordinates'][1], vehicle['coordinates'][0])
      if distance <= options['max_distance_km']
        count += 1
        coordinates = [vehicle['coordinates'][1], vehicle['coordinates'][0]]
        vehicles_nearby << {distance: distance, vin: vehicle['vin'], name: vehicle['name'],
                            address: vehicle['address'], coordinates: coordinates}
        markers << coordinates
      end
    end
    send_event("car2go-#{poi}", { :count =>count, :vehicles => vehicles_nearby, :markers => markers })
  end

end

# Distance function
def coorDist(lat1, lon1, lat2, lon2)
  earthRadius = 6371 # Earth's radius in KM

    # convert degrees to radians
    def convDegRad(value)
      unless value.nil? or value == 0
            value = (value/180) * Math::PI
      end
    return value
    end

  deltaLat = (lat2-lat1)
  deltaLon = (lon2-lon1)
  deltaLat = convDegRad(deltaLat)
  deltaLon = convDegRad(deltaLon)

  # Calculate square of half the chord length between latitude and longitude
  a = Math.sin(deltaLat/2) * Math.sin(deltaLat/2) +
      Math.cos((lat1/180 * Math::PI)) * Math.cos((lat2/180 * Math::PI)) *
      Math.sin(deltaLon/2) * Math.sin(deltaLon/2); 

  # Calculate the angular distance in radians
  c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))

  distance = earthRadius * c
  return distance
end
