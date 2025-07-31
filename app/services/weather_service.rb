require 'net/http'
require 'json'

class WeatherService
  BASE_URL = 'https://api.open-meteo.com/v1/forecast'
  GEOCODING_URL = 'https://geocoding-api.open-meteo.com/v1/search'

  def initialize(address)
    @address = address
  end

  def get_forecast
    Rails.logger.info "=== WEATHER SERVICE: Starting forecast for: #{@address}"
    
    # Check cache first
    cache_key = generate_cache_key(@address)
    cached_result = get_from_cache(cache_key)
    
    if cached_result
      Rails.logger.info "=== WEATHER SERVICE: Returning cached result for: #{@address}"
      return cached_result.merge(cached: true)
    end
    
    Rails.logger.info "=== WEATHER SERVICE: Cache miss, fetching fresh data for: #{@address}"
    
    coords = geocode_address
    Rails.logger.info "=== WEATHER SERVICE: Coordinates: #{coords}"
    
    if coords
      weather = fetch_weather(coords)
      Rails.logger.info "=== WEATHER SERVICE: Weather data: #{weather}"
      
      if weather
        result = {
          address: @address,
          temperature: weather['temperature'].round,
          feels_like: weather['temperature'].round,
          description: weather_description(weather['weathercode']),
          humidity: 65, # Approximate/static
          cached: false
        }
        
        # Cache the result for 30 minutes
        cache_result(cache_key, result)
        Rails.logger.info "=== WEATHER SERVICE: Cached result for 30 minutes"
        
        Rails.logger.info "=== WEATHER SERVICE: Final result: #{result}"
        result
      else
        Rails.logger.error "=== WEATHER SERVICE: No weather data returned"
        error("Weather data not available")
      end
    else
      Rails.logger.error "=== WEATHER SERVICE: No coordinates found"
      error("Location not found")
    end
  rescue => e
    Rails.logger.error "=== WEATHER SERVICE: Exception: #{e.message}"
    Rails.logger.error "=== WEATHER SERVICE: Backtrace: #{e.backtrace.first(5)}"
    error("Failed to fetch weather: #{e.message}")
  end

  private

  def geocode_address
    uri = URI("#{GEOCODING_URL}?name=#{URI.encode_www_form_component(@address)}&count=1")
    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      results = JSON.parse(response.body)['results']
      if results && !results.empty?
        { lat: results[0]['latitude'], lon: results[0]['longitude'] }
      else
        nil
      end
    else
      nil
    end
  rescue
    nil
  end

  def fetch_weather(coords)
    uri = URI("#{BASE_URL}?latitude=#{coords[:lat]}&longitude=#{coords[:lon]}&current_weather=true&temperature_unit=celsius")
    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)['current_weather']
    else
      nil
    end
  end

  def weather_description(code)
    {
      0 => "Clear sky",
      1 => "Partly cloudy", 2 => "Partly cloudy", 3 => "Partly cloudy",
      45 => "Foggy", 48 => "Foggy",
      51 => "Drizzle", 53 => "Drizzle", 55 => "Drizzle",
      61 => "Rain", 63 => "Rain", 65 => "Rain",
      71 => "Snow", 73 => "Snow", 75 => "Snow",
      95 => "Thunderstorm", 96 => "Thunderstorm", 99 => "Thunderstorm"
    }[code] || "Unknown"
  end

  def error(message)
    { error: message }
  end

  def generate_cache_key(address)
    # Normalize address for consistent caching
    normalized_address = address.strip.downcase.gsub(/\s+/, '_')
    "weather_forecast:#{normalized_address}"
  end

  def get_from_cache(cache_key)
    cached_data = $redis.get(cache_key)
    return nil unless cached_data
    
    JSON.parse(cached_data, symbolize_names: true)
  rescue JSON::ParserError, Redis::BaseError => e
    Rails.logger.error "=== WEATHER SERVICE: Cache read error: #{e.message}"
    nil
  end

  def cache_result(cache_key, result)
    # Remove the cached flag before storing
    cache_data = result.except(:cached)
    $redis.setex(cache_key, 30.minutes.to_i, cache_data.to_json)
  rescue Redis::BaseError => e
    Rails.logger.error "=== WEATHER SERVICE: Cache write error: #{e.message}"
    # Don't fail the request if caching fails
  end
end
