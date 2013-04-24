class MitfahrgelegenheitDe < Search
  def self.get_countries
    html = Nokogiri::HTML(open(
      'http://www.mitfahrgelegenheit.de/searches/search_abroad'
    ))

    list_countries = html.css('#LiftCountryFrom option').map do |option|
      { id: option['value'], name: option.text }
    end.to_json

    File.open('data/countries.json', 'w') do |f|
      f.puts list_countries
    end
  end

  def get_country_id name
    mfg_de = R18n::I18n.new('de', './i18n/')
    name = mfg_de.t.countries.send(name)

    File.open('data/countries.json', 'r') do |f|
      JSON.parse(f.gets).each do |country|
        if country['name'].downcase == name.downcase
          return country['id']
        end
      end
    end

    return false
  end

  def get_city_id country_id, city
    JSON.parse(open(
      "http://www.mitfahrgelegenheit.de/lifts/getCities/#{country_id}"
    ).read).each do |el|
      return el[1] if el[0].downcase == city.downcase
    end
  end

  def query
    @from_country_id = get_country_id @from_country
    @to_country_id = get_country_id @to_country

    uri = Addressable::URI.new
    uri.query_values = {
      country_from: @from_country_id,
      country_to: @to_country_id,
      city_from: get_city_id(@from_country_id, @from_city),
      city_to: get_city_id(@to_country_id, @to_city),
      radius_from: 0, radius_to: 0,
      date: 'date', tolerance: 4,
      day: @when_date.strftime('%d'),
      month: @when_date.strftime('%m'),
      year: @when_date.strftime('%Y')
    }
    [
      "http://www.mitfahrgelegenheit.de/searches/search_abroad?",
      uri.query
    ].join ''
  end

  def process
    html = Nokogiri::HTML(open(query))
    raise html.inspect
  end

end
