require 'logger'
require 'json'
require 'httpclient'
require 'uri'
require 'pp'

SDK_VERSION = '0.02'
API_VERSION = 'v2'

class Client
  attr_accessor :remote, :token, :no_verify_ssl, :log, :handle,
  :query, :submit, :logger, :config_path, :columns, :submission, :search_id
  def initialize params = {}
    params.each { |key, value| send "#{key}=", value }
    @handle = HTTPClient.new(:agent_name => 'rb-cif-sdk/' + SDK_VERSION)
    unless @verify_ssl
      @handle.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    @headers = {
      'Accept' => 'application/vnd.cif.v' + API_VERSION + '+json',
      'Authorization' => 'Token token=' + params['token'].to_s,
      'Content-Type' => 'application/json',
      'User-Agent' => 'cif-sdk-ruby/' + SDK_VERSION
    }
  end

  def _make_request(uri='',type='get',params={})

    case type
    when 'get'
      self.logger.debug { "uri: " + @remote + "#{uri}" }
      self.logger.debug { "params: #{params}" }

      uri = URI(@remote + uri)
      res = @handle.get(uri,params, @headers)
    when 'put'
      uri = URI(@remote)
      self.logger.debug { "uri: #{uri}.to_s" }
      res = @handle.post(uri,params['data'],@headers)
    end

    case res.status_code
    when 200...299
      return JSON.parse(res.body)
    when 300...399
      @logger.debug { "received: #{res.status_code}" }
    when 400...401
      @logger.warn { 'unauthorized, bad or missing token' }
    when 404
      @logger.warn { "invalid remote uri: #{uri}.to_s" }
    when 500...600
      @logger.fatal { 'router failure, contact administrator' }
    end
    return nil

  end

  def ping
    start = Time.now()

    rv = self._make_request(uri='/ping')
    return nil unless(rv)

    return (Time.now()-start)
  end

  def search(filters)
    if filters['id']
      res = self._make_request(uri="/observables/" + filters['id'],type='get')
    else
      res = self._make_request(uri="/observables",type='get',params=filters)
    end
    return res
  end

  def submit(data=nil)
    #  '{"observable":"example.com","confidence":"50",":tlp":"amber",
    #  "provider":"me.com","tags":["zeus","botnet"]}'
    #data = JSON.generate(data) if data.is_a?(::Hash)
    params = {
      'data' => data
    }
    res = self._make_request(uri='/observables',type='put',params)
    return nil unless(res)
    return res
  end

end

command = 'search'
logger = Logger.new(STDOUT)
#logger.level = logger::DEBUG

conf = {}
conf['logger'] = logger
conf['columns'] = ['reporttime','cc','confidence']
conf['config_path'] = ENV['HOME'] + '/.cif.yml'
conf['remote'] = 'https://10.0.0.10'
conf['token'] = 'bc6049e7c5d479db663e72cc3309dfe7d9dff7e734f7397d5886169ca8a9711d'

cif = Client.new(conf)
filters = {
  'query' => '61.240.144.116',
  'limit' => 1
}
puts cif.search(filters)
