require 'yaml'

# fleet info from http://en.wikipedia.org/wiki/Metrobus_(Washington,_D.C.)
articulated_buses = Array (5301..5452)
new_buses = Array (6100..8105)
new_buses += Array (3036..3087)

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

    body = JSON.parse(res.body)
    predictions = body['Predictions']
    processed_predictions = Array.new()
    num_buses = 0
    predictions.each do |prediction|
      if num_buses < prediction_limit
        new = new_buses.include? prediction['VehicleID'].to_i
        articulated = articulated_buses.include? prediction['VehicleID'].to_i
        processed_predictions.push( { destination: "#{prediction['DirectionText']}",
                                      minutes: "#{prediction['Minutes']}",
                                      route_id: prediction['RouteID'],
                                      vehicle_id: prediction['VehicleID'],
                                      new: new,
                                      articulated: articulated
        } )
        num_buses += 1
      end
    end
    send_event("wmata-#{stop_id}", { predictions: processed_predictions, stop_name: body['StopName'], agency_name: "Metrobus" })

  end
end
