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
      fc: @from_city, fi: @from_city_id,
      tc: @to_city, tci: @to_city_id,
      d: @when_date.strftime('%d/%m/%Y'),
      tp: 'BOTH', p: 1, n: 20, di: radius,
      t: 'tripsearch', a: 'searchtrip'
    }
    ["http://www.covoiturage.fr/recherche?", uri.query].join ''
  end

  def service
    @locale.engines.covoituragefr
  end

  def booking trip
    if trip.at_css('span.with_booking')
      true
    else
      false
    end
  end

  def cities_exist?
    @from_city_id = get_city_id @from_city
    @to_city_id = get_city_id @to_city

    if @from_city_id.nil? or @to_city_id.nil?
      false
    else
      true
    end
  end

  def link trip
    if trip.css('div.one-trip-action a').empty?
      ''
    else
      [
        'http://',
        service,
        trip.css('div.one-trip-action a').first['href']
                                         .delete("\n")
                                         .gsub('trajet',
                                               @locale.t.other.trip.to_s)
      ].join ''
    end
  end

  def places trip
    if trip.at_css 'span.nbseats-booking-manual'
      trip.css('span.nbseats-booking-manual').text.scan(/[0-9]+/i).first.to_i
    elsif trip.at_css 'span.nbseats b'
      trip.at_css('span.nbseats b').text.to_i
    elsif trip.at_css 'span.nbseats-booking-auto b'
      trip.css('span.nbseats-booking-auto b').text.to_i
    elsif trip.at_css 'span.no-seat-available'
      0
    else
      'NaN'
    end
  end

  def from trip
    if trip.at_css 'span.realfrom'
      trip.css('span.realfrom').text.split(' → ').first
    else
      trip.css('div.one-trip-info h2 a').text.split(' → ').first
    end
  end

  def to trip
    trip.css('div.one-trip-info h2 a').text.split(' → ')[1]
  end

  def date trip
    date_string, time_string = trip.css('span.date')[1].text.strip.split ' - '

    if date_string.downcase == 'demain'
      date_string = (Date.today + 1).strftime('%d %B')
    elsif date_string.downcase == 'aujourd\'hui'
      date_string = Date.today.strftime('%d %B')
    else
      date_string[0..7] = ''
      day_string, month_string = date_string.split ' '

      if month_string.index '.'
        month_string = Date.month_shorten_to_english(month_string[0..-1])
      else
        month_string = Date.month_to_english(month_string)
      end

      date_string = [ day_string, month_string ].join ' '
    end

    begin
      DateTime.strptime(
        [ date_string, time_string ].join(' '),
        '%d %B %Hh%M'
      )
    rescue
      raise date_string.inspect
      raise trip.css('span.date')[1].text.strip.inspect
      raise [ date_string, time_string ].join(' ').inspect
    end
  end

  def result trip
    link = link trip

    return nil if trip.css('span.date').first.text.strip == ': Trajet régulier'
    return nil if link.empty?

    Result.new(
      username: trip.css('a.displayname').text.delete("\n"),
      price: trip.css('span.price span').text.delete("\n"),
      date: date(trip),
      places: places(trip),
      service: service,
      from: from(trip),
      to: to(trip),
      link: link,
      booking: booking(trip)
    )
  end

  def process
    return nil if @locale.get.locale.code != 'fr'
    return nil unless cities_exist?

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
