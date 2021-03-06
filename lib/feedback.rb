class Feedback
  VARIABLES = [ :name, :email, :subject, :message ]

  def initialize hash
    VARIABLES.each do |variable|
      if hash.has_key? variable.to_s
        instance_variable_set "@#{variable}", hash[variable]
      else
        instance_variable_set "@#{variable}", false
      end
    end
  end

  def valid?
    @errors = Hash.new
    @locale = R18n::I18n.new(R18n.get.locale.code, './i18n/')

    VARIABLES.each do |variable|
      if instance_variable_get("@#{variable}").empty?
        @errors[variable] = @locale.t.errors.send(variable).empty
      end
    end

    email_regex = /^([0-9a-zA-Z]([-\.\w]*[0-9a-zA-Z])*@([0-9a-zA-Z][-\w]*[0-9a-zA-Z]\.)+[a-zA-Z]{2,9})$/i
    if not @email.match(email_regex) and not @errors.has_key? :email
      @errors[:email] = @locale.t.errors.email.invalid
    end

    if @errors.any?
      false
    else
      true
    end
  end

  def errors_to_json
    @errors.to_json
  end

  def send
    File.open('data/feedback.txt', 'a+') do |f|
      f.puts [ "----", @name, @email, @subject, @message, "----" ].join "\n"
    end

    Pony.mail(
      to: 'nogues.loic@gmail.com',
      via: :smtp,
      via_options: {
        :address        => 'ssl0.ovh.net',
        :port           => '587',
        :user_name      => 'metacarpooling@loicnogu.es',
        :password       => 'envoiture',
        :authentication => :plain,
        :domain         => "metacarpooling.com"
      },
      subject: @subject,
      body: @message
    )
  end

end
