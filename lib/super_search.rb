class SuperSearch
  ENGINES = [ 'CovoiturageFr', 'BessermitfahrenDe', 
              #'MitfahrzentraleDe',
              #'MitfahrgelegenheitDe',
              'FahrgemeinschaftDe', 
              'CovoituragelibreFr'  ]

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

  def process
    @results = @results.map do |result|
      result.process
    end.compact.flatten

    @results = remove_complete
    order_by_date
  end

end
