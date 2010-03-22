class HttpsVmRepository < HttpVmRepository

  def get 
    #TODO slap a '/' char on the end of self.uri if it doesn't have one, otherwise many servers return 403 
    url = URI.parse(URI.escape(self.uri))
    http = Net::HTTP.new(url.host, url.port)
    req = Net::HTTP::Get.new(url.path)
    http.use_ssl = true
    #req.basic_auth username, password
    response = http.request(req)
    return response.body
  end

end
