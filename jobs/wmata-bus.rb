# This script connects to WMATA's API. Therefore, you need a WMATA api key.
api_key = ENV['WMATA_API_KEY']
api_uri = 'http://api.wmata.com/NextBusService.svc/json/jPredictions'
stop_ids = [1002873, 1001947]


SCHEDULER.every '30s', :first_in => 0  do
  stop_ids.each do |stop_id|
    uri = URI("#{api_uri}?#{stop_id}&api_key=#{api_key}")
    req = Net::HTTP::Get.new(uri.request_uri)
    res = Net::HTTP.start(uri.hostname, uri.port) {|http|
      http.request(req)
    }

    predictions = JSON.parse(res.body)['Predictions']
    processed_predictions = Array.new()
    predictions.each do |prediction|
      processed_predictions.push( { label: "#{prediction['RouteID']} #{prediction['DirectionText']}", value: "#{prediction['Minutes']}"} )
    end
    puts processed_predictions
    send_event("wmata-#{stop_id}", { items: processed_predictions })
  end
end
