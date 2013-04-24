class Search
  def initialize search
    @from_country = search[:from][:country]
    @from_city = search[:from][:city]
    @to_country = search[:to][:country]
    @to_city = search[:to][:city]
    @when_date = Date.strptime(search[:when][:date], '%d-%m-%Y')
    @booking = search[:booking]
  end
end
