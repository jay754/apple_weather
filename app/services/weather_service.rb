require 'net/http'
require 'json'

class WeatherService
  BASE_URL = 'https://api.open-meteo.com/v1/forecast'
  GEOCODING_URL = 'https://geocoding-api.open-meteo.com/v1/search'
  CACHE_DURATION = 30.minutes
  DEFAULT_HUMIDITY = 65

  def initialize(address)
    @address = address
  end

  def get_forecast
    Rails.logger.info "Starting weather forecast for: #{@address}"
    
    cached_result = fetch_from_cache
    return add_cache_flag(cached_result, true) if cached_result

    fetch_fresh_weather_data
  rescue StandardError => e
    Rails.logger.error "Weather service error: #{e.message}"
    error_response("Failed to fetch weather: #{e.message}")
  end

  private

  def fetch_from_cache
    cache_key = generate_cache_key(@address)
    cached_data = get_from_cache(cache_key)
    
    if cached_data
      Rails.logger.info "Returning cached weather data for: #{@address}"
      cached_data
    end
  end

  def fetch_fresh_weather_data
    Rails.logger.info "Fetching fresh weather data for: #{@address}"
    
    coordinates = geocode_address
    return error_response("Location not found") unless coordinates

    weather_data = fetch_weather(coordinates)
    return error_response("Weather data not available") unless weather_data

    result = build_weather_response(weather_data)
    cache_result(result)
    add_cache_flag(result, false)
  end

  def geocode_address
    response = make_http_request(build_geocoding_url)
    return nil unless response

    parse_geocoding_response(response)
  end

  def fetch_weather(coordinates)
    response = make_http_request(build_weather_url(coordinates))
    return nil unless response

    parse_weather_response(response)
  end

  def build_geocoding_url
    "#{GEOCODING_URL}?name=#{URI.encode_www_form_component(@address)}&count=1"
  end

  def build_weather_url(coordinates)
    "#{BASE_URL}?latitude=#{coordinates[:lat]}&longitude=#{coordinates[:lon]}&current_weather=true&temperature_unit=celsius"
  end

  def make_http_request(url)
    uri = URI(url)
    response = Net::HTTP.get_response(uri)
    
    response.is_a?(Net::HTTPSuccess) ? JSON.parse(response.body) : nil
  rescue JSON::ParserError, SocketError, Timeout::Error
    nil
  end

  def parse_geocoding_response(response)
    results = response['results']
    return nil if results.nil? || results.empty?

    result = results.first
    { lat: result['latitude'], lon: result['longitude'] }
  end

  def parse_weather_response(response)
    response['current_weather']
  end

  def build_weather_response(weather_data)
    {
      address: @address,
      temperature: weather_data['temperature'].round,
      feels_like: weather_data['temperature'].round,
      description: weather_description(weather_data['weathercode']),
      humidity: DEFAULT_HUMIDITY
    }
  end

  def add_cache_flag(result, is_cached)
    result.merge(cached: is_cached)
  end

  def weather_description(code)
    WEATHER_CODES[code] || "Unknown"
  end

  def error_response(message)
    { error: message }
  end

  # Caching methods
  def generate_cache_key(address)
    normalized_address = address.strip.downcase.gsub(/\s+/, '_')
    "weather_forecast:#{normalized_address}"
  end

  def get_from_cache(cache_key)
    cached_data = $redis.get(cache_key)
    return nil unless cached_data
    
    JSON.parse(cached_data, symbolize_names: true)
  rescue JSON::ParserError, Redis::BaseError => e
    Rails.logger.error "Cache read error: #{e.message}"
    nil
  end

  def cache_result(result)
    cache_key = generate_cache_key(@address)
    cache_data = result.except(:cached)
    $redis.setex(cache_key, CACHE_DURATION.to_i, cache_data.to_json)
  rescue Redis::BaseError => e
    Rails.logger.error "Cache write error: #{e.message}"
    # Don't fail the request if caching fails
  end

  # Weather code mappings
  WEATHER_CODES = {
    0 => "Clear sky",
    1 => "Partly cloudy", 2 => "Partly cloudy", 3 => "Partly cloudy",
    45 => "Foggy", 48 => "Foggy",
    51 => "Drizzle", 53 => "Drizzle", 55 => "Drizzle",
    61 => "Rain", 63 => "Rain", 65 => "Rain",
    71 => "Snow", 73 => "Snow", 75 => "Snow",
    95 => "Thunderstorm", 96 => "Thunderstorm", 99 => "Thunderstorm"
  }.freeze
end