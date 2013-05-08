class MitfahrzentraleDe < Search
  LANGUAGES = { 'en' => 'GB', 'de' => 'D', 'fr' => 'F' }

  def self.get_countries
    html = Nokogiri::HTML(open(
      'http://www.mitfahrzentrale.de/index.php'
    ))

    list_countries = html.css('#abland option').map do |option|
      { id: option['value'], name: option.text }
    end.to_json

    File.open('data/mfz_countries_de.json', 'w') do |f|
      f.puts list_countries
    end
  end

  def get_country_id name
    mfz_de = R18n::I18n.new('de', './i18n/')
    name = mfz_de.t.countries.send(name)

    File.open('data/mfz_countries_de.json', 'r') do |f|
      JSON.parse(f.gets).each do |country|
        if country['name'].downcase == name.downcase
          return country['id']
        end
      end
    end

    return false
  end

  def query
    @from_country_id = get_country_id @from_country
    @to_country_id = get_country_id @to_country

    uri = Addressable::URI.new
    uri.query_values = {
      art: 100, frmpost: 1,
      STARTLAND: @from_country_id,
      ZIELLAND: @to_country_id,
      START: @from_city.downcase,
      ZIEL: @to_city.downcase,
      abdat: @when_date.strftime('%d.%m.%Y'),
      lang: LANGUAGES[@locale.get.locale.code]
    }

    [
      'http://www.mitfahrzentrale.de/suche.php?',
      uri.query
    ].join ''
  end

  def service
    'Mitfahrzentrale.de'
  end

  def link trip
    link = trip['onclick'].split(';').first
    [
      'http://',
      service,
      link.scan(/^location\.href\=\'([^']+)\'/i).first.first
    ].join ''
  end

  def date trip
    date_string = trip.css('td:nth-child(2)').text
    date_string[0..3] = ''
    time_string = trip.css('td:nth-child(5)').text.gsub(/(Uhr|o\'clock)/i, '').strip

    begin
      DateTime.strptime(
        [ date_string, time_string ].join(' '),
        '%d.%m.%Y %I:%M %p'
      )
    rescue
      raise [ date_string, time_string ].inspect
    end
  end

  def result trip
    Result.new(
      from: trip.css('td:nth-child(3)').text,
      to: trip.css('td:nth-child(4)').text,
      date: date(trip),
      booking: false,
      link: link(trip),
      service: service
    )
  end

  def process
    #raise query.inspect
    html = Nokogiri::HTML(open(query))
    html.css('div.mfz_box_body tr.mfz_rtrow').map do |trip|
      if trip.css('td:nth-child(2)').text.empty?
        nil
      else
        result trip
      end
    end.compact
  end

end
