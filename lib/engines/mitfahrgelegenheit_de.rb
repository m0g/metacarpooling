class MitfahrgelegenheitDe < Search
  DATE_FORMAT = {
    'en' => '%d/%m/%y %I:%M %p',
    'fr' => '%d.%m.%y %Hh%M',
    'de' => '%d.%m.%y %H.%M Uhr'
  }

  def self.get_countries
    html = Nokogiri::HTML(open(
      'http://www.mitfahrgelegenheit.de/searches/search_abroad'
    ))

    list_countries = html.css('#LiftCountryFrom option').map do |option|
      { id: option['value'], name: option.text }
    end.to_json

    File.open('data/mfg_countries_de.json', 'w') do |f|
      f.puts list_countries
    end
  end

  def get_country_id name
    mfg_de = R18n::I18n.new('de', './i18n/')
    name = mfg_de.t.countries.send(name)

    File.open('data/mfg_countries_de.json', 'r') do |f|
      JSON.parse(f.gets).each do |country|
        if country['name'].downcase == name.downcase
          return country['id']
        end
      end
    end

    return false
  end

  def get_city_id country_id, city
    white = Text::WhiteSimilarity.new

    JSON.parse(open(
      "http://www.#{service}/lifts/getCities/#{country_id}"
    ).read).each do |el|
      return el[1] if white.similarity(el[0].downcase, city.downcase) > 0.8
    end
    nil
  end

  def query
    uri = Addressable::URI.new
    query_values = {
      country_from: @from_country_id,
      country_to: @to_country_id,
      city_from: @from_city_id,
      #city_from: get_city_id(@from_country_id, @from_city),
      city_to: @to_city_id,
      #city_to: get_city_id(@to_country_id, @to_city),
      radius_from: @from_radius, radius_to: @to_radius,
      date: 'date', tolerance: @when_margin,
      day: @when_date.strftime('%d'),
      month: @when_date.strftime('%m'),
      year: @when_date.strftime('%Y')
    }

    uri.query_values = query_values

    [
      #'http://',
      #MFG_SECRET,
      '/searches/search_abroad?',
      uri.query
    ].join ''
  end

  def booking trip
    if trip.at_css('td.column-8 span.icon_booking')
      true
    else
      false
    end
  end

  def service
    @locale.t.engines.mitfahrgelegenheit
  end

  def link trip
    link = [
      'http://www.',
      service,
      trip.css('td.column-1 a').first['href']
    ]. join ''
  end

  def date trip
    date_string = [
      trip.css('td.column-3').text,
      trip.css('td.column-4').text
    ].join(' ').strip

    if trip.css('td.column-4').text.empty?
      date_string << ' 00.00 Uhr'
    end

    DateTime.strptime(date_string, DATE_FORMAT['de'])
  end

  def result trip
    Result.new(
      price: trip.css('td.column-6').text.gsub(/\sEUR$/i, ' €'),
      date: date(trip),
      service: Unicode::capitalize(service),
      places: trip.css('td.column-5').text.to_i,
      from: trip.css('td.column-2').text.gsub(/\s\(.*\)/i, ''),
      to: trip.css('td.column-3').text.gsub(/\s\(.*\)/i, ''),
      link: link(trip),
      booking: booking(trip)
    )
  end

  def process
    booking_el = 'td.column-8 span.icon_booking'

    begin
      @when_date.strftime('%d.%m.%Y')
    rescue
      @when_date = Date.strptime(@when_date, '%d-%m-%Y')
    end

    @from_country_id = get_country_id @from_country
    @to_country_id = get_country_id @to_country
    @from_city_id = get_city_id(@from_country_id, @from_city)
    @to_city_id = get_city_id(@to_country_id, @to_city)

    return nil if @from_city_id.nil? or @to_city_id.nil?

    uri = URI "http://#{MFG_SECRET}"
    res = nil

    Net::HTTP.SOCKSProxy('127.0.0.1', 9050).start(uri.host, uri.port) do |http|
      res = http.get query
    end

    html = Nokogiri::HTML res.body

    html.css('table.list tr.odd, table.list tr.even').map do |trip|
      if not trip.at_css(booking_el) and @booking != 'yes'
        result trip
      elsif trip.at_css(booking_el) and @booking != 'no'
        result trip
      else
        nil
      end
    end.compact
  end

end
