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

    #from_lat, from_lng = get_city_lat_lng @from_country, @from_city
    #to_lat, to_lng = get_city_lat_lng @to_country, @to_city

    origin = {
      PlaceID: "null",
      Address: [ @from_city, from_country_de ].join(', '),
      Accuracy: "",
      LocalityName: @from_city,
      CountryCode: get_country_code(@from_country),
      CountryName: from_country_de, # We need to use the german name
      Longitude: @from_lng,
      Latitude: @from_lat,
      PostalCode: "",
      Placetype: "geo"
    }.to_json

    destination = {
      PlaceID: "null",
      Address: [ @to_city, to_country_de ].join(', '),
      Accuracy: "",
      LocalityName: @from_city,
      CountryCode: get_country_code(@to_country),
      CountryName: to_country_de, # We need to use the german name
      Longitude: @to_lng,
      Latitude: @to_lat,
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
    [
      'http://www.',
      service,
      trip['onclick'].scan(/^location.href\s=\s\'(.+)\'$/i).first
    ].join ''
  end

  def date trip, date_string
    if trip.css('td:nth-child(5)').text.empty?
      time_string = '00:00'
    else
      time_string = trip.css('td:nth-child(5)').text.scan /^\d{2}:\d{2}/i
    end

    time_string = '00:00' if time_string.empty?

    date_string = [ date_string, time_string ].join ' '

    begin
      DateTime.strptime date_string, '%d.%m.%Y %H:%M'
    rescue
      raise time_string.inspect
    end
  end

  def result trip, date_string
    Result.new(
      price: trip.css('td:nth-child(6)').text.scan(/[0-9,]+\s[€]/i).first,
      service: Unicode::capitalize(service),
      date: date(trip, date_string),
      places: trip.css('td:nth-child(7)').text.to_i,
      from: trip.css('td:nth-child(1)').text.strip,
      to: trip.css('td:nth-child(3)').text.strip,
      link: link(trip),
      booking: false
    )
  end

  def process
    begin
      @when_date.strftime('%d.%m.%Y')
    rescue
      @when_date = Date.strptime(@when_date, '%d-%m-%Y')
    end

    date_string = ''

    html = Nokogiri::HTML(open(query))
    html.css('#tableResults tr').map do |trip|
      if trip['class'].nil? and not trip.at_css('td:nth-child(4)')
        date_string = trip.css('td').text.scan(/[0-9\.]+/i).first
        nil
      elsif trip['class'] == 'trTrip'
        if trip.at_css('td:nth-child(8) a img')\
          and trip.css('td:nth-child(8) a img').first['src'] == '/gfx/ico/db.png'
          nil
        else
          result trip, date_string
        end
      else
        nil
      end
    end.compact
  end
end
