class Result
  VARIABLES = [ :username, :price, :booking, :service, :link, :date, :places, :from, :to ]

  def initialize hash
    VARIABLES.each do |variable|
      if hash.has_key? variable
        instance_variable_set "@#{variable}", hash[variable]
      else
        instance_variable_set "@#{variable}", false
      end
    end
  end

  VARIABLES.each do |variable|
    define_method variable do
      instance_variable_get "@#{variable}"
    end
  end
end
