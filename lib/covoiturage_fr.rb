class CovoiturageFr < Search
  def query
    uri = Addressable::URI.new
    uri.query_values = {
      fc: @from_city, fi: 30510, tc: @to_city, tci: 28530,
      d: "09%2F04%2F2013", tp: 'BOTH', p: 1, n: 20,
      t: 'tripsearch', a: 'searchtrip'
    }
    ["http://www.covoiturage.fr/recherche?", uri.query].join ''
  end

  def result trip
    Result.new(
      name: trip.css('a.displayname').text.delete("\n"),
      phone: trip.css('span.price span').text.delete("\n")
    )
  end

  def process
    html = Nokogiri::HTML(open(query))
    html.css('li.one-trip').map {|trip| result(trip)}
  end
end
