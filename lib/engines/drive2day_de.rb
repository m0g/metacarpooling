class Drive2dayDe < Search
  DATE_FORMAT = {
    'en' => '%m/%d/%y %I:%M%p',
    'de' => '%d.%m.%y %H:%M'
  }

  def self.get_countries
    html = Nokogiri::HTML(open("http://www.drive2day.de"))

    list_countries = html.css('#search_action_country_from_id option').map do |option|
      { id: option['value'], name: option.text }
    end.to_json

    File.open('data/d2d_countries_de.json', 'w') do |f|
      f.puts list_countries
    end
  end

  def get_country_id name
    mfg_de = R18n::I18n.new('de', './i18n/')
    name = mfg_de.t.countries.send(name)

    File.open('data/d2d_countries_de.json', 'r') do |f|
      JSON.parse(f.gets).each do |country|
        if country['name'].downcase == name.downcase
          return country['id']
        end
      end
    end

    return false
  end

  def get_city_id city, country_code
    uri = Addressable::URI.new
    uri.query_values = {
      'search_action[thing_from_name]' => city,
      all: 1,
      search_string: city,
      country_id: country_code
    }
    # http://www.drive2day.de/shared/ac_places_names?search_action%5Bthing_from_name%5D=berli&all=1&search_string=berli&country_id=276


    raise "http://www.#{service}/shared/ac_places_names?#{uri.query}"
    html = Nokogiri::HTML(open(
      "http://www.#{service}/shared/ac_places_names?#{uri.query}"
    ))

    raise html.inspect
  end

  def service
    @locale.t.engines.drive2dayde
  end

  def post_params
    uri = Addressable::URI.new
    uri.query_values = {
      utf8: '✓',
      #authenticity_token: 'P/5hDfgoiBzTmAC9l3oowIntfZY2bY97cIabJvB08B0=',
      #'search_action[previous_id]' => 3077076,
      #'search_action[trip_type_id]' => 701925182,
      'search_action[country_from_id]' => @from_country_id,
      'search_action[thing_from_name]' => @from_city,
      'search_action[from_radius_km]' => 0,
      'search_action[country_to_id]' => @to_country_id,
      'search_action[thing_to_name]' => @to_city,
      'search_action[to_radius_km]' => 0,
      'search_action[date_at]' => @when_date.strftime('%d.%m.%Y'),
      'search_action[days_tolerance]' => @when_margin,
      'search_action[remember]' => 0
    }
    uri.query
  end

  def link trip
    [
      'http://www.',
      service,
      trip['onclick'].match(/\/[A-Za-z\d\-]+/)[0]
    ].join ''
  end

  def date trip
    date_string = trip.xpath('./td[4]').text.match(/[\d\/\.]+/)[0]
    time_string = trip.xpath('./td[5]').text.strip

    date_string = [ date_string, time_string ].join ' '
    #raise date_string.inspect

    DateTime.strptime(date_string, DATE_FORMAT[@locale.get.locale.code])
  end

  def result trip
    Result.new(
      price: trip.xpath('./td[7]').text.strip,
      date: date(trip),
      service: Unicode::capitalize(service),
      places: trip.xpath('./td[6]').text.to_i,
      from: trip.xpath('./td[2]/span').text,
      to: trip.xpath('./td[3]').text.strip,
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

    @from_country_id = get_country_id @from_country
    @to_country_id = get_country_id @to_country
    #@from_city_id = get_city_id @from_city, @from_country_id

    uri = URI "http://www.#{service}"
    http = Net::HTTP.new "www.#{service}"

    res = http.post '/search_actions', post_params

    return nil if res.header['location'].nil?

    html = Nokogiri::HTML(open(res.header['location']))

    html.css('table.search tr.clickable').map do |trip|
      unless trip.at_css('#train_link')
        #raise result(trip).inspect
        result trip
      end
    end.compact
  end
end
