require 'logger'
require 'json'
require 'httpclient'
require 'uri'

API_VERSION = '2'
SDK_VERSION = '0.0.1a'

class Cifclient
    attr_accessor :remote, :token, :verify_ssl, :timeout
    def initialize(remote, token)
      @remote = remote
      @token = token
      @logger = Logger.new(STDOUT)
      @handle = HTTPClient.new(:agent_name => 'cif-sdk-ruby/0.0.1')
      @handle.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE

      @headers = {
        'Accept' => 'application/vnd.cif.v' + API_VERSION + 'json',
        'Authorization' => 'Token token=' + @token,
        'Content-Type' => 'application/json',
        'User-Agent' => 'cif-sdk-ruby/' + SDK_VERSION
        }
    end

    def make_request(uri='',type='get',params={})
      case type
      when 'get'
        uri = URI(@remote + uri)
        response = @handle.get(uri,params,@headers)
      end
      case response.status_code
        when 200...299
          return JSON.parse(response.body)
        when 300...399
          @logger.debug { "received: #{response.status_code}" }
        when 400...401
          @logger.warn { 'unauthorized, bad or missing token' }
        when 404
          @logger.warn { "invalid remote uri: #{uri.to_s}" }
        when 500...600
          @logger.fatal { 'router failure, contact administrator' }
      end
      return nil
    end

    def search(limit=10,sort='lasttime',filters={})
      filters[:limit] = limit
      filters[:sort] = sort
      res = make_request(uri='/observables',type='get',filters)
    end

    def ping

      start = Time.now
      res = make_request(uri='/ping')
      return nil unless(res)
      return (Time.now() - start)
    end
end

cif = Cifclient.new("https://10.0.0.10", "bc6049e7c5d111db663e72cc1109dfe7d9dff7e734f7397d5006169ca8a0011d")
puts cif.ping
puts cif.search(limit=2,:query=>'61.240.144.116')
