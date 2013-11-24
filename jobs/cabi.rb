# This script connects to WMATA's API. Therefore, you need a WMATA api key.
api_uri = 'http://capitalbikeshare.com/data/stations/bikeStations.xml'
station_ids = []

require 'xmlsimple'

SCHEDULER.every '30s', :first_in => 0  do
  uri = URI("#{api_uri}")
  req = Net::HTTP::Get.new(uri.request_uri)
  res = Net::HTTP.start(uri.hostname, uri.port) {|http|
    http.request(req)
  }
  stations = XmlSimple.xml_in(res.body, {})['station']
  stations.each do |station|
    bike_station = [
      { label: "Available Bikes", value: "#{station['nbBikes'][0]}"},
      { label: "Empty Docks", value: "#{station['nbEmptyDocks'][0]}"}
    ]
    send_event("cabi-#{station['id'][0]}", { items: bike_station })
  end
end
