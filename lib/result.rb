class Result
  def initialize hash
    @name = hash[:name]
    @phone = hash[:phone]
    @booking = false
    @booking = hash[:booking] if hash.has_key? :booking
    @service = hash[:service]
    @link = hash[:link]
    @date = hash[:date]
  end

  def name
    @name
  end

  def phone
    @phone
  end

  def booking
    @booking.to_s
  end

  def service
    @service
  end
  
  def link
    @link
  end

  def date
    @date
  end
end
