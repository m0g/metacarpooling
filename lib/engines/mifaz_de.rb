class MifazDe < Search
  def query
    uri = Addressable::URI.new
    uri.query_values = {
      f: 'getEntries',
      startlatitude: @from_lat,
      startlongitude: @from_lng,
      goallatitude: @to_lat,
      goallongitude: @to_lng,
      journeydate: @when_date.strftime('%Y-%m-%d'),
      format: 'json'
    }

    "http://www.mifaz.de/ws/MifazInterface.php?#{uri.query}"
  end

  def date trip
    date_string = [
      @when_date.strftime('%Y-%m-%d'),
      trip['starttimebegin']
    ].join ' '

    DateTime.strptime date_string, '%Y-%m-%d %H:%M'
  end

  def result trip
    Result.new(
      service: 'Mifaz.de',
      username: trip['username'],
      link: trip['url'],
      date: date(trip),
      price: '?€',
      #places: '?',
      from: trip['startloc'],
      to: trip['goalloc'],
      booking: false
    )
  end

  def process
    begin
      @when_date.strftime('%d.%m.%Y')
    rescue
      @when_date = Date.strptime(@when_date, '%d-%m-%Y')
    end

    @from_country_code = get_country_code @from_country
    @to_country_code = get_country_code @to_country

    if @locale.get.locale.code != 'de'
      @from_city = Translate.get_city_name(
        @from_city,
        @from_country_code,
        @locale.get.locale.code
      )
      @to_city = Translate.get_city_name(
        @to_city,
        @to_country_code,
        @locale.get.locale.code
      )
    end

    JSON.parse(open(query).read)['entries'].map do |trip|
      result trip
    end
  end
end
