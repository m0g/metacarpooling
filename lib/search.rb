class Search
  def initialize search
    @from_city = search[:from][:city]
    @to_city = search[:to][:city]
  end
end
