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
    end

    def print
      @handle = HTTPClient.new(:agent_name => 'rb-cif-sdk/0.0.1')
      @handle.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE     
      @logger.debug{@remote + ", " + @token}
      @logger.debug{@handle.ssl_config.verify_mode}
      uri = URI(@remote + '/ping')
      headers = {
        'Authorization' => 'Token token=' + @token,
        'Content-Type' => 'application/json'
      }
      @logger.debug{"uri: #{uri}"}
      res = @handle.get(uri,params={},headers)
      @logger.debug{res.status_code}
      @logger.debug{JSON.parse(res.body)}
    end
end

cif = Cifclient.new("https://10.0.0.10", "bc6049e7c5d479db663e72cc3309dfe7d9dff7e734f7397d5886169ca8a9711d")
cif.print
