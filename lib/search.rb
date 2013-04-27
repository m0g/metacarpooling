class Search
  def initialize search
    @locale = R18n::I18n.new(R18n.get.locale.code, './i18n/')

    @from_country = search[:from][:country]
    @from_city = search[:from][:city]
    @from_radius = search[:from][:radius]

    @to_country = search[:to][:country]
    @to_city = search[:to][:city]
    @to_radius = search[:to][:radius]

    @when_date = Date.strptime(search[:when][:date], '%d-%m-%Y')
    @when_margin = search[:when][:margin]

    @booking = search[:booking]
  end
end
