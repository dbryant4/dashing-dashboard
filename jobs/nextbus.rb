require 'xmlsimple'

api_uri = 'http://webservices.nextbus.com/service/publicXMLFeed?command=predictions'

stops = [
  { 'agency_tag' => 'dc-circulator',
    'route_tag' => 'green',
    'stop_tag' => 'colu16th_n'
  }
]

SCHEDULER.every '30s', :first_in => 0  do

  stops.each do |stop|
    uri = URI("#{api_uri}&a=#{stop['agency_tag']}&r=#{stop['route_tag']}&s=#{stop['stop_tag']}")
    req = Net::HTTP::Get.new(uri.request_uri)
    res = Net::HTTP.start(uri.hostname, uri.port) {|http|
      http.request(req)
    }
    arrivals = Hash.new

    predictions = XmlSimple.xml_in(res.body, {})['predictions']
    arrivals['agencyTitle'] = predictions[0]['agencyTitle']
    arrivals['routeTitle']  = predictions[0]['routeTitle']
    arrivals['stopTitle']   = predictions[0]['stopTitle']
    arrivals['routeTag']    = predictions[0]['routeTag']
    arrivals['busArrivals'] = Array.new

    predictions[0]['direction'].each do |direction|
      direction['prediction'].each do |prediction|
        arrivals['busArrivals'].push (
          {
            minutes: prediction['minutes'],
            vehicle: prediction['vehicle'],
            direction: direction['title']
          }
        )
      end
    end
    send_event("nextbus-#{stop['agency_tag']}-#{stop['route_tag']}-#{stop['stop_tag']}", arrivals)
  end
end
