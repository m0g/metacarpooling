class SuperSearch
  def order_by_date
    @results.sort do |x, y|
      x.date.to_time.to_i <=> y.date.to_time.to_i
    end
  end

  def remove_complete
    @results.map do |result|
      if result.places == 0
        nil
      else
        result
      end
    end.compact
  end

  def initialize search
    @results = ENGINES.map do |engine|
      countries = AVAILABLE_COUNTRIES[engine.downcase]

      if countries.include? search[:from][:country] and countries.include? search[:to][:country]
        Object::const_get(engine).new(search)
      end

    end.compact.flatten

  end

  def validate_fields
    return false if @results.empty?
    @results.first.validate_fields
  end

  def validate_coordinates
    @lat_lng = get_lat_lng @results.first

    if @lat_lng.nil?
      false
    else
      true
    end
  end

  def get_lat_lng result
    from = Geocoding.get_city_lat_lng result.from_country, result.from_city
    to = Geocoding.get_city_lat_lng result.to_country, result.to_city

    if from.nil? or to.nil?
      nil
    else
      [ from, to ]
    end
  end

  def process
    @results = @results.map do |result|
      result.set_lat_lng(@lat_lng) unless @lat_lng.nil?
      result.process
    end.compact.flatten

    @results = remove_complete
    order_by_date
  end

end
