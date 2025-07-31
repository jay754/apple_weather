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
          humidity: 65 # Approximate/static
        }
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
end
