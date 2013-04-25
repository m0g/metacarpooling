class CovoiturageFr < Search
  def get_city_id city
    result = open("http://www.covoiturage.fr/api/ajax_getCityListAutoComplete.php?q=#{CGI::escape(city.downcase)}&limit=30").read
    result.split(/\n/).first.split('|')[1] unless result.empty?
  end

  def radius
    (@from_radius.to_i + @to_radius.to_i) / 200
  end

  def query
    uri = Addressable::URI.new
    uri.query_values = {
      fc: @from_city, fi: get_city_id(@from_city),
      tc: @to_city, tci: get_city_id(@to_city),
      d: @when_date.strftime('%d/%m/%Y'),
      tp: 'BOTH', p: 1, n: 20, di: radius,
      t: 'tripsearch', a: 'searchtrip'
    }
    ["http://www.covoiturage.fr/recherche?", uri.query].join ''
  end

  def booking trip
    if trip.at_css('span.with_booking')
      true
    else
      false
    end
  end

  def link trip
    if trip.css('div.one-trip-action a').empty?
      ''
    else
      [
        'http://covoiturage.fr',
        trip.css('div.one-trip-action a').first['href'].delete("\n")
      ].join ''
    end
  end

  def result trip
    Result.new(
      username: trip.css('a.displayname').text.delete("\n"),
      price: trip.css('span.price span').text.delete("\n"),
      date: trip.css('span.date').first.text,
      service: 'covoiturage.fr',
      link: link(trip),
      booking: booking(trip)
    )
  end

  def process
    html = Nokogiri::HTML(open(query))
    html.css('li.one-trip').map do |trip| 
      if not trip.at_css('span.with_booking') and @booking != 'yes'
        result trip
      elsif trip.at_css('span.with_booking') and @booking != 'no'
        result trip
      else
        nil
      end
    end.compact
  end
end
