class CovoituragelibreFr < Search
  def get_city_id city, url
    uri = Addressable::URI.new
    uri.query_values = {
      COMMUNE: city,
      PAYS: 'FR'
    }

    query_string = [
      'http://covoiturage-libre.fr/ajax/',
      url, '_flag.php', uri
    ].join('')

    html = Nokogiri::HTML(open(query_string))
    city = html.css("#ville_#{url} li a").first

    return false if city.nil?

    [ city['lat'], city['lon'] ]
  end

  def get_from_city_id
    get_city_id @from_city, 'depart'
  end

  def get_to_city_id
    get_city_id @to_city, 'arrivee'
  end

  def post_params
    uri = Addressable::URI.new
    uri.query_values = {
      PAYS_DEPART: get_country_code(@from_country),
      PAYS_ARRIVEE: get_country_code(@to_country),
      DEPART: @from_city,
      DEPART_LAT: @from_lat,
      DEPART_LON: @from_lng,
      ARRIVEE: @to_city,
      ARRIVEE_LAT: @to_lat,
      ARRIVEE_LON: @to_lng,
      DATE_PARCOURS: @when_date.strftime('%d-%m-%Y'),
      button: 'Rechercher',
      TYPE: 'Conducteur',
      DEPART_KM: @from_radius,
      ARRIVEE_KM: @to_radius,
      TRI: 'DATE HEURE',
      srctoken: @token
    }
    uri.query
  end

  def get_token_and_cookie
    uri = URI('http://www.covoiturage-libre.fr/')
    res = Net::HTTP.get_response(uri)

    [
      Nokogiri::HTML(res.body).css('#srctoken').first['value'],
      res.response['set-cookie'].split('; ')[0]
    ]
  end

  def link trip
    [
      'http://covoiturage-libre.fr/',
      trip.css('a.lienannonce').first['href']
    ].join ''
  end

  def date trip
    date_string, time_string = trip.css('td:nth-child(2) p.gros2').text.strip.split(' - ')
    date_string = date_string.scan(/[0-9]{2}\s[a-zA-Z]+\s[0-9]{4}/i).first

    day, month, year = date_string.split ' '
    month = Date.month_to_english month

    date_string = [ day, month, year, time_string ].join ' '
    DateTime.strptime date_string, '%d %B %Y %H:%M'
  end

  def result trip
    from, to = trip.css('td:nth-child(2) p:first-child').text.split('→')

    Result.new(
      username: trip.css('td:first-child tr:first-child td:last-child').text,
      price: trip.css('td.vert span.gros strong').text,
      date: date(trip),
      places: trip.css('td:first-child tr:nth-child(2) td:last-child strong').text.to_i,
      service: 'covoiturage-libre.fr',
      from: from,
      to: to,
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

    @from_lat, @from_lng =  get_from_city_id()
    @to_lat, @to_lng =  get_to_city_id()

    @token, cookie = get_token_and_cookie

    headers = { 'Cookie' => cookie }
    uri = URI 'http://www.covoiturage-libre.fr'
    http = Net::HTTP.new 'www.covoiturage-libre.fr'

    res = http.post '/recherche.php', post_params, headers
    redirection = res.header['location']

    html = Nokogiri::HTML(open("http://www.covoiturage-libre.fr/#{redirection}", "Cookie" => cookie))
    html.css('table.annonce tr').map do |trip|
      if trip.at_css 'td.vert'
        result trip
      else
        nil
      end
    end.compact
  end
end
