class Search
  def initialize search
    @from_city = search[:from][:city]
    @to_city = search[:to][:city]
    @when_date = Date.strptime(search[:when][:date], '%d-%m-%Y')
    @booking = search[:booking]
  end
end
