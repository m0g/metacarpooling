class SuperSearch
  ENGINES = [ 'CovoiturageFr', 'BessermitfahrenDe', 'MitfahrzentraleDe',
              'MitfahrgelegenheitDe' ]

  def order_by_date
    @results.sort do |x, y|
      x.date.to_time.to_i <=> y.date.to_time.to_i
    end
  end

  def initialize search
    @results = ENGINES.map do |engine|
      #Object::const_get(engine).new(search).process
      Object::const_get(engine).new(search)
    end.flatten
  end

  def validate_fields
    @results.first.validate_fields
  end

  def process
    @results = @results.map do |result|
      result.process
    end.flatten

    order_by_date
  end

end
