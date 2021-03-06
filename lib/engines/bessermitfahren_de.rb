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

    return nil if exotic_result.empty?

    exotic_result[2].gsub(/[()']/, '').split(',')[0]
  end

  def post_params
    {
      from: @from_city_id,
      to: @to_city_id,
      tmp_from: @from_city,
      tmp_to: @to_city,
      #people: 1,
      date: @when_date.strftime('%d.%m.%Y')
    }
  end

  def link trip
    link = [
      'http://www.bessermitfahren.de',
      trip['href']
    ]. join ''
  end

  def date trip
    date_string = [
      trip.css('span.date').text[-8..-1],
      trip.css('span.time').text
    ].join(' ')

    begin
      DateTime.strptime date_string, '%d.%m.%y %H:%M Uhr'
    rescue
      raise date_string.inspect
    end
  end

  def result trip
    Result.new(
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
    begin
      @when_date.strftime('%d.%m.%Y')
    rescue
      @when_date = Date.strptime(@when_date, '%d-%m-%Y')
    end

    @from_city_id = get_city_id(@from_country, @from_city)
    @to_city_id = get_city_id(@to_country, @to_city)

    return nil if @from_city_id.nil? or @to_city_id.nil?

    http = Net::HTTP.new "www.bessermitfahren.de"
    http.use_ssl = false

    res_get = http.request(Net::HTTP::Get.new('/'))
    cookie = res_get.response['set-cookie']

    request = Net::HTTP::Post.new '/'
    request.set_form_data post_params
    request["Cookie"] = cookie

    res = http.request(request)

    redirection = res.header['location']

    html = Nokogiri::HTML(open(redirection, "Cookie" => cookie))
    html.css('#resultlist li a').map do |trip|
      result trip
    end
  end
end
