require 'yaml'


wmata_config = YAML.load_file('wmata-config.yaml')

# This script connects to WMATA's API. Therefore, you need a WMATA api key.
api_keys = wmata_config['wmata-api-keys']
api_uri = 'http://api.wmata.com/StationPrediction.svc/json/GetPrediction/'

SCHEDULER.every '30s', :first_in => 0  do
  wmata_config['rail']['stations'].each do |station, options|
    api_key = api_keys.sample
    codes = options['codes'].join(',')

    if options['prediction_limit']
      prediction_limit = options['prediction_limit']
    else
      prediction_limit = wmata_config['rail']['defaults']['prediction_limit']
    end

    if options['char_limit']
      char_limit = options['char_limit']
    else
      char_limit = wmata_config['rail']['defaults']['char_limit']
    end

    uri = URI("#{api_uri}#{codes}?api_key=#{api_key}")
    req = Net::HTTP::Get.new(uri.request_uri)
    res = Net::HTTP.start(uri.hostname, uri.port) {|http|
      http.request(req)
    }

    next_trains = JSON.parse(res.body)['Trains']
    trains = Array.new()
    num_trains = 0
    next_trains.each do |train|
      if num_trains < prediction_limit then
        trains.push( { label: "#{train['Line']} #{train['DestinationName'][0..char_limit]}", value: "#{train['Min']}"} )
        num_trains += 1
      end
    end
    
    send_event("wmata-#{station}", { items: trains })
  end
end
