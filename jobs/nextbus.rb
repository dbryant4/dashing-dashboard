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
    predictions = XmlSimple.xml_in(res.body, {})['predictions'][0]['direction'][0]
    arrivals = Array.new
    predictions['prediction'].each do |prediction|
      arrivals.push (
        { label: "#{predictions['title']}", value: "#{prediction['minutes']}" }
      )
    end
    send_event("nextbus-#{stop['agency_tag']}-#{stop['route_tag']}-#{stop['stop_tag']}", { items: arrivals })
  end
end
