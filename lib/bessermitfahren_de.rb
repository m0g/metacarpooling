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

    exotic_result = open(city_query(country_city)).read.split('new Array')
    exotic_result[2].gsub(/[()']/, '').split(',')[0]
  end

  def post_params
    {
      from: get_city_id(@from_country, @from_city),
      to: get_city_id(@to_country, @to_city),
      tmp_from: @from_city,
      tmp_to: @to_city,
      people: 1,
      date: @when_date.strftime('%d.%m.%Y')
    }
  end

  def link trip
    link = [
      'http://www.bessermitfahren.de',
      trip.first[1]
    ]. join ''
  end

  def date trip
    date_string = [
      trip.css('span.date').text,
      trip.css('span.time').text
    ].join(' ')
    date_string[0..3] = ''

    DateTime.strptime date_string, '%d.%m.%y %H:%M Uhr'
  end

  def result trip
    Result.new(
      username: 'Unknown',
      price: trip.css('span.price').text,
      date: date(trip),
      places: trip.css('span.people').text.scan(/[0-9]+/i).first.to_i,
      service: 'bessermitfahren.de',
      from: trip.css('span.from'),
      to: trip.css('span.to'),
      link: link(trip),
      booking: false
    )
  end

  def process
    uri = URI('http://www.bessermitfahren.de/')
    res = Net::HTTP.post_form(uri, post_params)
    redirection = res.header['location']
    cookie = res.response['set-cookie'].split('; ')[0]

    html = Nokogiri::HTML(open(redirection, "Cookie" => cookie))
    html.css('#resultlist li a').map do |trip|
      result trip
    end
  end
end
