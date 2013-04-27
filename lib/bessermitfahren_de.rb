class BessermitfahrenDe < Search
  def city_query country_city
    uri = Addressable::URI.new
    uri.query_values = {
      q: country_city, _: Time.now.to_i
    }
    [
      "http://www.bessermitfahren.de/search.php?",
      uri.query
    ].join ''
  end

  def get_city_id country, city
    country_city = [ city, country ].join ', '

    open(city_query(country_city)).read
  end

  def process
    raise get_city_id(@from_country, @from_city).inspect

    #uri = URI('http://www.example.com/search.cgi')
    #res = Net::HTTP.post_form(uri, 'q' => 'ruby', 'max' => '50')
    #puts res.body
  end
end
