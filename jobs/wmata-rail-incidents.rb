# This script connects to WMATA's API. Therefore, you need a WMATA api key.
api_key = ENV['WMATA_API_KEY']
api_uri = 'http://api.wmata.com/Incidents.svc/json/Incidents'

SCHEDULER.every '30s', :first_in => 0  do
  uri = URI("#{api_uri}?api_key=#{api_key}")
  req = Net::HTTP::Get.new(uri.request_uri)
  res = Net::HTTP.start(uri.hostname, uri.port) {|http|
    http.request(req)
  }
  
  incidents = JSON.parse(res.body)['Incidents']
  if incidents.empty? then
    inc = [{ label: "No Rail Incidents", value: "" }]
  else
    inc = Array.new()
    incidents.each do |incident|
      inc.push( { label: "#{incident['Description']}", value: ""} )
    end
  end
  
  send_event("wmata-railincidents", { items: inc })
end
