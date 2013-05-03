class SuperSearch
  def order_by_date
    @results.sort do |x, y|
      x.date.to_time.to_i <=> y.date.to_time.to_i
    end
  end

  def initialize search
    @results = [
      CovoiturageFr.new(search).process,
      BessermitfahrenDe.new(search).process,
      MitfahrzentraleDe.new(search).process,
      MitfahrgelegenheitDe.new(search).process
    ].flatten
  end
end
