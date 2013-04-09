class Result
  def initialize hash
    @name = hash[:name]
    @phone = hash[:phone]
  end

  def name
    @name
  end

  def phone
    @phone
  end
end
