class Geocoding
  def self.get_city_lat_lng country, city
    uri = Addressable::URI.new
    uri.query_values = {
      address: [ city, country ].join(', '),
      sensor: false
    }

    location = JSON.parse(open(
      "http://maps.googleapis.com/maps/api/geocode/json?#{uri.query}"
    ).read)

    if location['status'] == 'ZERO_RESULTS'
      nil
    else
      location = location['results'].first['geometry']['location']

      [
        location['lat'].to_f,
        location['lng'].to_f
      ]
    end
  end
end
