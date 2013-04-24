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

  def result trip
    if trip.at_css('td.column-8 span.sprite_icons-icon_table_booking')
      booking = true
    else
      booking = false
    end

    link = [
      'http://mitfahrgelegenheit.de',
      trip.css('td.column-1 a').first['href']
    ]. join ''

    Result.new(
      username: 'Unknown',
      price: trip.css('td.column-6').text,
      date: trip.css('td.column-5').text,
      service: 'Mitfahrgelegenheit.de',
      link: link,
      booking: booking
    )
  end

  def process
    html = Nokogiri::HTML(open(query))
    html.css('table.lift_list tr.link_hover').map do |trip|
      if not trip.at_css('td.column-8 span.sprite_icons-icon_table_booking') and @booking != 'yes'
        result trip
      elsif trip.at_css('td.column-8 span.sprite_icons-icon_table_booking') and @booking != 'no'
        result trip
      else
        nil
      end
    end.compact
  end

end
