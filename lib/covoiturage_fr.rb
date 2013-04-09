class CovoiturageFr < Search
  def query
    [
      "http://www.covoiturage.fr/recherche?",
      "fc=#{@from_city}&fi=30510",
      "&tc=#{@to_city}&tci=28530&",
      "d=09%2F04%2F2013",
      "&to=BOTH&p=1&n=20&t=tripsearch&a=searchtrip"
    ].join ''
  end

  def result trip
    Result.new(
      trip.css('a.displayname').text.delete("\n"),
      trip.css('span.price span').text.delete("\n")
    )
  end

  def process
    html = Nokogiri::HTML(open(query))
    html.css('li.one-trip').map {|trip| result(trip)}
  end
end
