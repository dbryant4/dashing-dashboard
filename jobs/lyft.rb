require 'yaml'

lyft_config = YAML.load_file('lyft-config.yaml')

api_uri="https://api.lyft.com/users/#{lyft_config['user']['id']}/location"

SCHEDULER.every '30s', :first_in => 0  do
  uri = URI("#{api_uri}")
  http = Net::HTTP.new(uri.hostname, uri.port)
  http.use_ssl = true
  #http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request = Net::HTTP::Put.new(uri.path, initheader = {
    'User-Agent' => 'Lyft:android:4.4.2:1.3.1.21',
    'user-device' => 'LGE Nexus 5',
    'Content-Type' => 'application/json; charset=UTF-8',
    'session' => lyft_config['user']['session_id'],
    'Accept' => 'application/vnd.lyft.app+json;version=7',
    'Authorization' => "fbAccessToken #{lyft_config['user']['fbAccessToken']}",
    'accept_language' => 'en_US',
    'Host' => 'api.lyft.com',
    'Connection' => 'Keep-Alive',
  })
  lyft_config['points_of_interest'].each { |poi, options|
    body = {
      :lat => options['latitude'],
      :lng => options['longitude'],
      :markerLat => options['latitude'],
      :markerLng => options['longitude']
    }
    request.body = body.to_json
    res = http.request(request)
    drivers = JSON.parse(res.body)['drivers']
    send_event("lyft-#{poi}", { :count => drivers.length, :drivers => drivers, :origin => [options['latitude'], options['longitude']] })
  }
end
