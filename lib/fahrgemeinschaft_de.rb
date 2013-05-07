class FahrgemeinschaftDe < Search
  def get_city_lat_lng country, city
    uri = Addressable::URI.new
    uri.query_values = {
      address: [ city, country ].join(', '),
      sensor: false
    }

    location = JSON.parse(open(
      "http://maps.googleapis.com/maps/api/geocode/json?#{uri.query}"
    ).read)['results'].first['geometry']['location']

    [
      location['lat'].to_f,
      location['lng'].to_f
    ]
  end

  def query
    fgs_de = R18n::I18n.new('de', './i18n/')
    from_country_de = fgs_de.t.countries.send @from_country
    to_country_de = fgs_de.t.countries.send @to_country

    from_lat, from_lng = get_city_lat_lng @from_country, @from_city
    to_lat, to_lng = get_city_lat_lng @to_country, @to_city

    origin = {
      PlaceID: "null",
      Address: [ @from_city, from_country_de ].join(', '),
      Accuracy: "",
      LocalityName: @from_city,
      CountryCode: "DE",
      CountryName: from_country_de, # We need to use the german name
      Longitude: from_lng,
      Latitude: from_lat,
      PostalCode: "",
      Placetype: "geo"
    }.to_json

    destination = {
      PlaceID: "null",
      Address: [ @to_city, to_country_de ].join(', '),
      Accuracy: "",
      LocalityName: @from_city,
      CountryCode: "DE",
      CountryName: to_country_de, # We need to use the german name
      Longitude: to_lng,
      Latitude: to_lat,
      PostalCode: "",
      Placetype: "geo"
    }.to_json

    uri = Addressable::URI.new
    uri.query_values = {
      selOriginRadius: 15,
      selDestinationRadius: 25,
      beliebig: 0,
      selDateDay: @when_date.strftime('%d'),
      selDateMonth: @when_date.strftime('%m'),
      selDateYear: @when_date.strftime('%Y'),
      edtOrigin: origin,
      edtDestination: destination
    }

    [
      "http://www.fahrgemeinschaft.de/search.php?",
      uri.query
    ].join ''
  end

  def service
    'fahrgemeinschaft.de'
  end

  def link trip
    #raise trip.css('td:nth-child(8)').text.inspect

    [
      'http://www.',
      service,
      trip['onclick'].scan(/^location.href\s=\s\'(.+)\'$/i).first
    ].join ''
  end

  def result trip
    Result.new(
      price: trip.css('td:nth-child(6)').text.scan(/[0-9,]+\s[€]/i).first,
      service: Unicode::capitalize(service),
      places: trip.css('td:nth-child(7)').text.to_i,
      from: trip.css('td:nth-child(1)').text.split(', ').first.strip,
      to: trip.css('td:nth-child(3)').text.split(', ').first.strip,
      link: link(trip),
      booking: false
    )
  end

  def process
    date_string = ''

    html = Nokogiri::HTML(open(query))
    html.css('#tableResults tr').map do |trip|
      if trip['class'].nil? and not trip.at_css('td:nth-child(4)')
        date_string = trip.css('td').text.scan(/[0-9\.]+/i).first
      elsif trip['class'] == 'trTrip'
        result trip
      end
    end
  end
end
