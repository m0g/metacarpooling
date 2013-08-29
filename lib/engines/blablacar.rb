class Blablacar < Search
  def query
    uri = Addressable::URI.new
    uri.query_values = {
      fn: "#{@from_city}, #{@from_country}",
      fc: "#{@from_lat}|#{@from_lng}",
      fcc: @from_country_code,
      tn: "#{@to_city}, #{@to_country}",
      tc: "#{@to_lat}|#{@to_lng}",
      tcc: @to_country_code,
      db: @when_date.strftime('%d/%m/%Y'),
      sort: 'trip_date', order: 'asc'
    }

    [
      'http://www.', service,
      '/', @locale.t.engines.uri.blablacar, '?',
      uri.query
    ].join ''
  end

  def service
    @locale.t.engines.blablacar
  end

  def link trip
    [
      'http://www.',
      service,
      trip.css('a.trip-search-oneresult').first['href']
    ].join ''
  end

  def date trip
    date_string = trip.css('h3.time').text

    date_string.gsub! 'Today', Date.today.strftime('%d %B')
    date_string.gsub! /(Morgen|Tomorrow)/, (Date.today + 1).strftime('%d %B')

    date_string = date_string.scan(/[\d]{2}\.?\s[A-Za-z]+\s-\s[\d]{2}:[\d]{2}/i).first

    if @locale.get.locale.code == 'en'
      DateTime.strptime(date_string.downcase, '%d %B - %H:%M')
    else
      day, month, time = date_string.scan /[^-\s\.]+/i
      month = Date.month_to_english month
      date_string = [ day, month, time ].join ' '
      DateTime.strptime(date_string.downcase, '%d %B %H:%M')
    end
  end

  def result trip
    Result.new(
      price: trip.css('div.price strong span').text,
      service: Unicode::capitalize(service),
      date: date(trip),
      places: trip.css('div.availability strong').text.to_i,
      from: trip.css('h3.fromto span.from.trip-roads-stop').text,
      to: trip.css('h3.fromto span.trip-roads-stop:not(.from)').text,
      link: link(trip),
      booking: false
    )
  end

  def process
    return nil if @locale.get.locale.code == 'fr'

    begin
      @when_date.strftime('%d.%m.%Y')
    rescue
      @when_date = Date.strptime(@when_date, '%d-%m-%Y')
    end

    @from_country_code = get_country_code @from_country
    @to_country_code = get_country_code @to_country

    html = Nokogiri::HTML(open(query))
    html.css('ul.trip-search-results li.trip').map do |trip|
      result trip
    end.compact
  end
end
