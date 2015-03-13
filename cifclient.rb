require 'logger'
require 'json'
require 'httpclient'
require 'uri'
require 'pp'

class Cifclient
    attr_accessor :remote, :token, :verify_ssl, :timeout
    def initialize(remote, token)
      @remote = remote
      @token = token
      @logger = Logger.new(STDOUT)
      @handle = HTTPClient.new(:agent_name => 'rb-cif-sdk/0.0.1')
      @handle.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE

      @headers = {
        'Authorization' => 'Token token=' + @token,
        'Content-Type' => 'application/json'
      }
    end

    def make_request(uri='',type='get',params={})

      @logger.debug{@remote + ", " + @token}

      case type
      when 'get'
        @logger.debug{"uri: #{uri}"}
        response = @handle.get(uri,params,@headers)
        @logger.debug{response.status_code}
        @logger.debug{JSON.parse(response.body)}
      end
    end

    def search(filters = {},limit=1,sort='lasttime')
      filters[:limit] = limit
      filters[:sort] = sort
      @logger.debug{filters}
      uri = URI(@remote + '/observables')
      res = make_request(uri,'get',filters)
    end

    def ping
      uri = URI(@remote + '/ping')

      start = Time.now
      res = make_request(uri)
      return nil unless(res)
      return (Time.now() - start)
    end
end

cif = Cifclient.new("https://10.0.0.10", "bc6049e7c5d479db663e72cc3309dfe7d9dff7e734f7397d5886169ca8a9711d")
#puts cif.ping
cif.search(:query=>'61.240.144.116')
