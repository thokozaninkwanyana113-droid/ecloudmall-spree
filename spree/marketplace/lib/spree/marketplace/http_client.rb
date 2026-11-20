require 'net/http'
require 'json'

module Spree
  module Marketplace
    # Tiny Net::HTTP wrapper for payment / logistics provider calls (keeps gems out of the engine).
    class HttpClient
      Response = Struct.new(:status, :body, :json, keyword_init: true) do
        def success?
          status.to_i.between?(200, 299)
        end
      end

      def initialize(open_timeout: 5, read_timeout: 15)
        @open_timeout = open_timeout
        @read_timeout = read_timeout
      end

      def get(url, headers: {})
        request(Net::HTTP::Get, url, headers: headers)
      end

      def post_json(url, payload, headers: {})
        request(Net::HTTP::Post, url, body: payload.to_json, headers: headers.merge('Content-Type' => 'application/json'))
      end

      def post_form(url, body, headers: {})
        request(Net::HTTP::Post, url, body: body, headers: headers.merge('Content-Type' => 'application/x-www-form-urlencoded'))
      end

      private

      def request(klass, url, body: nil, headers: {})
        uri = URI.parse(url)
        req = klass.new(uri)
        headers.each { |k, v| req[k] = v }
        req['Accept'] ||= 'application/json'
        req.body = body if body
        res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https',
                                                  open_timeout: @open_timeout, read_timeout: @read_timeout) do |http|
          http.request(req)
        end
        json = begin
          JSON.parse(res.body.to_s)
        rescue JSON::ParserError
          nil
        end
        Response.new(status: res.code.to_i, body: res.body.to_s, json: json)
      end
    end
  end
end
