module Gmaps4rails

  class Autocomplete
    include BaseNetMethods

    attr_reader :input, :language, :raw, :protocol, :sensor, :key, :output

    def initialize(input, options = {})
      raise Gmaps4rails::AutocompleteInvalidQuery, "You must provide a starting reference" if input.blank?

      @input  = input
      @language = options[:language] || "en"
      @raw      = options[:raw]      || false
      @protocol = options[:protocol] || "http"
      @sensor   = options[:sensor]   || false
      @key      = options[:key]
      @output   = options[:output]   || "json"
      @types    = options[:types]    || ""
      @location = options[:location] || ""
      @radius   = options[:radius]   || ""
      raise Gmaps4rails::AutocompleteInvalidQuery, "You must provide an API key" if @key.blank?
    end

    # returns an array of hashes with the following keys:
    # - lat: mandatory for acts_as_gmappable
    # - lng: mandatory for acts_as_gmappable
    # - matched_address: facultative
    # - bounds:          facultative
    # - full_data:       facultative
    def get_predictions
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
      if @output == "json"
        "#{protocol}://maps.googleapis.com/maps/api/place/autocomplete/json?input=#{input}&sensor=#{sensor}&language=#{language}&key=#{key}&raw=#{raw}&location=#{location}&radius=#{radius}&types=#{types}"
      else
        "#{protocol}://maps.googleapis.com/maps/api/place/autocomplete/xml?input=#{input}&sensor=#{sensor}&language=#{language}&key=#{key}&raw=#{raw}&location=#{location}&radius=#{radius}&types=#{types}"
      end
    end

    def raise_net_status
      raise Gmaps4rails::AutocompleteNetStatus, "The request sent to google was invalid (not http success): #{base_request}.\nResponse was: #{response}"
    end

    def raise_query_error
      raise Gmaps4rails::AutocompleteStatus, "The address you passed seems invalid, status was: #{parsed_response["status"]}.\nRequest was: #{base_request}"
    end

  end

end
