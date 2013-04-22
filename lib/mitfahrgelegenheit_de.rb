class MitfahrgelegenheitDe < Search
  def self.get_countries
    html = Nokogiri::HTML(open(
      'http://www.mitfahrgelegenheit.de/searches/search_abroad'
    ))
    html.css('#LiftCountryFrom option').map do |option|
      { id: option['value'], name: option.text }
    end
  end
end
