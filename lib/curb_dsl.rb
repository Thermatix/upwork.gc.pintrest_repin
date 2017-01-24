require "curb"
require 'cgi'

module Curb_DSL

  def self.included(base)
    base.extend Singleton
    base.instance_eval do
      attr_reader :curl, :headers,:payload, :username, :password, :auth_type, :uri, :ssl, :redirects, :type_converter,:cookies, :form_field_name, :form_fields

      [:get, :post, :put, :delete, :head, :options, :patch, :link, :unlink].each do |func_name|
        define_method func_name do |&block|
          make_request_of func_name.to_s.upcase, &block
        end
      end

      [:password,:username,:payload, :auth_type, :uri, :ssl, :redirects,:type_converter,:cookies,:form_field_name,:error_handler].each do |func_name|
        define_method "set_#{func_name}" do |value|
          self.instance_variable_set :"@#{func_name}", value
        end
      end
    end

    def form_field name,value
      @form_fields ||= []
      if @form_field_name
        @form_fields.push(Curl::PostField.content([("%[%]" % [@form_field_name,name]),value.to_s]))
      else
        @form_fields.push(Curl::PostField.content(name ,value.to_s))
      end
    end



  end

  module Singleton
    def request(&block)
      puts block
      self.new(&block).body
    end

    def query_params(value)
      Curl::postalize(value)
    end
  end



  def initialize(&block)
    @headers = {}
    instance_eval(&block) if block
  end

  def header(name, content)
    @headers[name] = content
  end

  def make_request_of(request_method,&block)
    @resp_cookies = {}
    @curl = Curl::Easy.new(@uri) do |http|
      setup_request request_method, http
    end
    @curl.ssl_verify_peer = @ssl ||false
    # @curl.ignore_content_length = true
    if @form_fields
      @curl.http_post(*@form_field)
    else
      if @payload
        @curl.http_post(@url,get_payload)
      else
        @curl.http request_method
      end
    end
    if @curl.response_code == 301
      @uri =  @curl.redirect_url
      make_request_of request_method
    end
    if @curl.response_code != 200
      if @error_handler
        puts @error_handler.call
      else
      end
    end
  end

  def status_code
    @curl.response_code
  end

  def decode_html(string)
    CGI.unescapeHTML(string)
  end

  def encode_html(string)
    CGI.escapeHTML(string)
  end

  def post_body
    get_payload
  end

  def body
    @curl.body
  end

  def response_cookies
    if @resp_cookies.empty?
      @curl.on_header {|header| @resp_cookies[$1] = $2 if header =~ /^Set-Cookie: ([^=])=([^;]+;)/}
      @resp_cookies
    else
      @resp_cookies
    end
  end

  def query_params(value)
    Curl::postalize(value)
  end


  private


  def setup_request(method,http)
    http.headers['request-method'] = method.to_s
    http.headers.update(headers || {})
    http.max_redirects = @redirects || 3
    http.post_body = get_payload || nil
    http.http_auth_types = @auth_type || nil
    http.username = @username || nil
    http.password = @password || nil
    http.useragent = "curb"
    http.multipart_form_post = @form_fields ? true : false
    if @cookies
      http.enable_cookies = true
      http.cookies = (@cookies.is_a? String) ? @cookies : @cookies.inject("") {|cookies,data| "%s%s=%s;" % data.unshift(cookies) }
    end
    http
  end


  def get_payload
    if @type_converter
      @type_converter.call(@payload)
    else
      @payload
    end
  end

end
