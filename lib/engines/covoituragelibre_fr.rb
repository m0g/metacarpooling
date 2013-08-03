class CovoituragelibreFr < Search
  def get_city_id city, country_code, url
    uri = Addressable::URI.new
    uri.query_values = {
      COMMUNE: city,
      PAYS: country_code
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
    get_city_id @from_city, @from_country_code, 'depart'
  end

  def get_to_city_id
    get_city_id @to_city, @to_country_code, 'arrivee'
  end

  def post_params
    uri = Addressable::URI.new
    uri.query_values = {
      PAYS_DEPART: @from_country_code,
      PAYS_ARRIVEE: @to_country_code,
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
    date_string, time_string = trip.css('td[width="450"] p.gros2').text.strip.split(' - ')
    date_string = date_string.scan(/[0-9]{2}\s[[:alpha:]]+\s[0-9]{4}/i).first

    day, month, year = date_string.split ' '
    month = Date.month_to_english month

    date_string = [ day, month, year, time_string ].join ' '
    DateTime.strptime date_string, '%d %B %Y %H:%M'
  end

  def result trip
    from, to = trip.xpath('./tr/td[2]/p[1]').text.split('→')

    Result.new(
      username: trip.css('td[width="300"]').first
                    .xpath('./table/tr[1]/td[3]').text,
      price: trip.css('td.vert span.gros strong').text,
      date: date(trip),
      places: trip.xpath('./tr/td[1]/table/tr[2]/td[2]/strong').text.to_i,
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

    @from_country_code = get_country_code @from_country
    @to_country_code = get_country_code @to_country

    @from_lat, @from_lng = get_from_city_id()
    @to_lat, @to_lng =  get_to_city_id()

    @token, cookie = get_token_and_cookie

    headers = { 'Cookie' => cookie }
    uri = URI 'http://www.covoiturage-libre.fr'
    http = Net::HTTP.new 'www.covoiturage-libre.fr'

    res = http.post '/recherche.php', post_params, headers
    redirection = res.header['location']

    html = Nokogiri::HTML(open(
      "http://www.covoiturage-libre.fr/#{redirection}",
      "Cookie" => cookie
    ))

    html.css('table.annonce').map do |trip|
      if trip.at_css 'tr td.vert'
        result trip
      else
        nil
      end
    end.compact
  end
end
