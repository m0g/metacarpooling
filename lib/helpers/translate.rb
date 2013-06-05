class Translate
  def self.get_city_name name, country_code, to_lang
    uri = Addressable::URI.new
    uri.query_values = {
      name: name.downcase,
      country: country_code,
      featureCode: 'PPLC',
      maxRows: 10,
      type: 'rdf',
      username: 'metacarpooling',
      lang: to_lang.downcase
    }

    begin
      JSON.parse(open(
        "http://api.geonames.org/searchJSON?#{uri.query}"
      ).read)['geonames'].first['name']
    rescue
      Unicode::capitalize name
    end
  end
end
