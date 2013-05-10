class CovoituragelibreFr < Search
  def get_city_id city, url
    uri = Addressable::URI.new
    uri.query_values = {
      COMMUNE: city,
      PAYS: 'FR'
    }

    query = [
      'http://covoiturage-libre.fr/ajax/',
      url, '_flag.php', uri
    ].join('')

    html = Nokogiri::HTML(open(query))
    city = html.css('#ville_depart li a').first

    [ city['lat'], city['lon'] ]
  end

  def get_from_city_id
    get_city_id @from_city, 'depart'
  end

  def get_to_city_id
    get_city_id @to_city, 'arrivee'
  end

  def query
  end

  def process
    from_lat, from_lng =  get_from_city_id()
    to_lat, to_lng =  get_to_city_id()
    raise to_lat.inspect
  end
end
