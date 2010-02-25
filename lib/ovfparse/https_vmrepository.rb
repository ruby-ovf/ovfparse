class HttpsVmRepository < HttpVmRepository

  def get 
    url = URI.parse(self.uri)
    http = Net::HTTP.new(url.host, url.port)
    req = Net::HTTP::Get.new(url.path)
    http.use_ssl = true
    #req.basic_auth username, password
    response = http.request(req)
    return response.body
  end

end
