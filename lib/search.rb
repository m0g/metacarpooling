class Search
  VARIABLES = [ :from_country, :from_city, :from_radius, :to_country, :to_city,
                :to_radius, :when_margin ]

  def initialize search
    @locale = R18n::I18n.new(R18n.get.locale.code, './i18n/')
    @booking = search[:booking]

    begin
      @when_date = Date.strptime(search[:when][:date], '%d-%m-%Y')
    rescue
      @when_date = false
    end

    VARIABLES.each do |variable|
      first_key, second_key = variable.to_s.split('_')

      if search.has_key?(first_key) and search[first_key].has_key?(second_key)
        instance_variable_set "@#{variable}", search[first_key][second_key]
      else
        instance_variable_set "@#{variable}", false
      end
    end
  end

  def validate_fields
    VARIABLES << :when_date

    VARIABLES.each do |variable|
      return false unless instance_variable_get "@#{variable}"
    end

    begin
      @when_date.strftime('%d.%m.%Y')
    rescue
      @when_date = Date.strptime(@when_date, '%d-%m-%Y')
    end

    return false if @when_date < Date.today

    true
  end

  VARIABLES.each do |variable|
    define_method variable do
      instance_variable_get "@#{variable}"
    end
  end

  def get_country_code country_name
    COUNTRIES.each do |country|
      if country['name'] == country_name.downcase
        return country['code'].upcase
      end
    end

    nil
  end
end
