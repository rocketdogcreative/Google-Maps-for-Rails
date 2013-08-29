module Gmaps4rails

  class Geocoder
    include BaseNetMethods

    attr_reader :address, :language, :raw, :protocol, :sensor, :client, :crypto

    def initialize(address, options = {})
      raise Gmaps4rails::GeocodeInvalidQuery, "You must provide an address" if address.blank?
      # added optional sensor param as well as client (client id for enterprise) and crypto (crypto key for enterprise,
      # key not to be sent with request but to be used to create a signature for the request)

      @address  = address
      @language = options[:language] || "en"
      @raw      = options[:raw]      || false
      @protocol = options[:protocol] || "http"
      @sensor   = options[:sensor]   || false
      @client   = options[:client]   || ""
      @crypto   = options[:crypto]   || ""
    end

    # returns an array of hashes with the following keys:
    # - lat: mandatory for acts_as_gmappable
    # - lng: mandatory for acts_as_gmappable
    # - matched_address: facultative
    # - bounds:          facultative
    # - full_data:       facultative
    def get_coordinates
      checked_google_response do
        return parsed_response if raw
        parsed_response["results"].inject([]) do |memo, result|
          memo << {
                   :lat             => result["geometry"]["location"]["lat"],
                   :lng             => result["geometry"]["location"]["lng"],
                   :matched_address => result["formatted_address"],
                   :bounds          => result["geometry"]["bounds"],
                   :full_data       => result
                  }
        end
      end
    end

    private

    def base_request
      # Check that crypto key was not included
      if @crypto.blank?
        "#{protocol}://maps.googleapis.com/maps/api/geocode/json?language=#{language}&address=#{address}&sensor=#{sensor}"
      else
        # create instance variable from url
        full_url = "#{protocol}://maps.googleapis.com/maps/api/geocode/json?language=#{language}&address=#{address}&sensor=#{sensor}"
        # create the initial partial url to form signature
        partial_url = full_url.gsub("#{protocol}://maps.googleapis.com", "")
        # append the client id to the partial url to form signature
        partial_url = partial_url + "&client=#{client}"
        # decodde the crypto key to form signature
        decoded_crypto_key = Base64.urlsafe_decode64("#{crypto}")
        # encode partial url to form signature
        encoded_partial_url = URI::encode(partial_url)
        # Create url safe base64 encoded signature with HMAC-SHA1
        signature = CGI.escape(Base64.urlsafe_encode64("#{OpenSSL::HMAC.digest('sha1', decoded_crypto_key, encoded_partial_url)}"))
        # reform url
        url_to_send = "#{protocol}://maps.googleapis.com" + partial_url + "&signature=" + signature
        url_to_send
      end
    end

    def raise_net_status
      raise Gmaps4rails::GeocodeNetStatus, "The request sent to google was invalid (not http success): #{base_request}.\nResponse was: #{response}"
    end

    def raise_query_error
      raise Gmaps4rails::GeocodeStatus, "The address you passed seems invalid, status was: #{parsed_response["status"]}.\nRequest was: #{base_request}"
    end

  end

end
