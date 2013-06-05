class Recaptcha
  def initialize challenge, response, remote
    @challenge = challenge
    @response = response
    @remote = remote
  end

  def post_params
    uri = Addressable::URI.new
    uri.query_values = {
      privatekey: RECAPTCHA[:private_key],
      remoteip: @remote,
      challenge: @challenge,
      response: @response
    }
    uri.query
  end

  def valid?
    http = Net::HTTP.new 'www.google.com'
    res = http.post '/recaptcha/api/verify', post_params

    @error = res.body.split(/\r?\n/)[0] != 'true'
    true unless @error
  end

  def error?
    @error
  end
end
