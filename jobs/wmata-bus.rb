require 'yaml'

wmata_config = YAML.load_file('wmata-config.yaml')

# This script connects to WMATA's API. Therefore, you need a WMATA api key.
api_keys = wmata_config['wmata-api-keys']
api_uri = 'http://api.wmata.com/NextBusService.svc/json/jPredictions'
config_defaults = wmata_config['bus']['defaults']
stop_ids = wmata_config['bus']['stops']

SCHEDULER.every '30s', :first_in => 0  do
  stop_ids.each do |stop_id, options|
    api_key = api_keys.sample
    uri = URI("#{api_uri}?StopID=#{stop_id}&api_key=#{api_key}")
    req = Net::HTTP::Get.new(uri.request_uri)
    res = Net::HTTP.start(uri.hostname, uri.port) {|http|
      http.request(req)
    }

    if options != nil and options['prediction_limit']
      prediction_limit = options['prediction_limit']
    else
      prediction_limit = wmata_config['bus']['defaults']['prediction_limit']
    end

    if options != nil and options['char_limit']
      char_limit = options['char_limit'] - 1
    else
      char_limit = wmata_config['bus']['defaults']['char_limit'] - 1
    end

    predictions = JSON.parse(res.body)['Predictions']
    processed_predictions = Array.new()
    num_buses = 0
    predictions.each do |prediction|
      if num_buses < prediction_limit
        processed_predictions.push( { label: "#{prediction['RouteID']} #{prediction['DirectionText'][0..char_limit]}", value: "#{prediction['Minutes']}"} )
        num_buses += 1
      end
    end
    send_event("wmata-#{stop_id}", { items: processed_predictions })

  end
end
