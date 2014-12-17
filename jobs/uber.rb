require 'yaml'

uber_config = YAML.load_file('uber-config.yaml')

# This script connects to Ubers API and needs a server token.
# To get one, go here: api.uber.com
server_token = uber_config['server_token']
time_estimates_api_uri = "https://api.uber.com/v1/estimates/time"
products_api_uri = "https://api.uber.com/v1/products"
price_estimates_api_uri = "https://api.uber.com/v1/estimates/price"

SCHEDULER.every '30s', :first_in => 0  do
  uber_config['points_of_interest'].each do |poi, options|
    uri = URI("#{products_api_uri}?latitude=#{options['latitude']}&longitude=#{options['longitude']}")
    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(uri.request_uri)
    request['Authorization'] = "Token #{server_token}"
    res = http.request(request)
    products = JSON.parse(res.body)['products']
    images = {}
    products.each do |product|
      images[product['product_id']] = product['image']
    end

    uri = URI("#{price_estimates_api_uri}?start_latitude=#{options['latitude']}&start_longitude=#{options['longitude']}&end_latitude=#{options['latitude']}&end_longitude=#{options['longitude']}")
    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(uri.request_uri)
    request['Authorization'] = "Token #{server_token}"
    res = http.request(request)

    surge_multipliers = {}
    prices = JSON.parse(res.body)['prices']
    prices.each do |price|
      surge_multipliers[price['product_id']] = price['surge_multiplier']
    end

    uri = URI("#{time_estimates_api_uri}?start_latitude=#{options['latitude']}&start_longitude=#{options['longitude']}")
    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(uri.request_uri)
    request['Authorization'] = "Token #{server_token}"
    res = http.request(request)

    times = JSON.parse(res.body)['times']
    times.each do |time|
      time['estimate'] = time['estimate'].to_i / 60
      time['estimate'] = time['estimate'].round(0)
      time['image'] = images[time['product_id']]
      time['surge_multiplier'] = surge_multipliers[time['product_id']]
    end

    send_event("uber-times-#{poi}", { :times => times, :poi_name => poi, :origin => [options['latitude'], options['longitude']] })
  end

end
