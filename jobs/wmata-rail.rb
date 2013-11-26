require 'yaml'

# This script connects to WMATA's API. Therefore, you need a WMATA api key.
api_keys = YAML.load_file('wmata-config.yaml')['wmata-api-keys']
api_uri = 'http://api.wmata.com/StationPrediction.svc/json/GetPrediction/'
station_mappings = {
  'galleryplace' => 'B01,F01',
  'metrocenter' => 'A01,C01',
  'columbiaheights' => 'E04',
  'woodleypark' => 'A04'
}

SCHEDULER.every '30s', :first_in => 0  do
  station_mappings.each do |station, codes|
    api_key = api_keys.sample
    uri = URI("#{api_uri}#{codes}?api_key=#{api_key}")
    req = Net::HTTP::Get.new(uri.request_uri)
    res = Net::HTTP.start(uri.hostname, uri.port) {|http|
      http.request(req)
    }

    next_trains = JSON.parse(res.body)['Trains']
    trains = Array.new(7)
    num_trains = 0
    next_trains.each do |train|
      if num_trains < 7 then
        trains.push( { label: "#{train['Line']} #{train['DestinationName']}", value: "#{train['Min']}"} )
        num_trains += 1
      end
    end
    
    send_event("wmata-#{station}", { items: trains })
  end
end
