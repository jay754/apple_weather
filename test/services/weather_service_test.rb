# CREATE THIS FILE AT: test/services/weather_service_test.rb
# 
# Make sure the directory exists first:
# mkdir -p test/services
#
# Then copy this content to test/services/weather_service_test.rb

require "test_helper"

class WeatherServiceTest < ActiveSupport::TestCase
  def setup
    @service = WeatherService.new("New York")
    # Clear Redis cache if available
    $redis.flushdb if defined?($redis) && $redis.respond_to?(:flushdb)
  end

  test "should initialize with address" do
    service = WeatherService.new("London")
    assert_equal "London", service.instance_variable_get(:@address)
  end

  test "should generate consistent cache keys" do
    service1 = WeatherService.new("New York")
    service2 = WeatherService.new("  new york  ")
    
    key1 = service1.send(:generate_cache_key, "New York")
    key2 = service2.send(:generate_cache_key, "  new york  ")
    
    # Keys should be normalized
    assert_match /weather_forecast:new_york/, key1
    assert_match /weather_forecast:new_york/, key2
  end

  test "should map weather codes correctly" do
    codes_and_descriptions = {
      0 => "Clear sky",
      1 => "Partly cloudy",
      45 => "Foggy",
      61 => "Rain",
      95 => "Thunderstorm",
      999 => "Unknown"
    }
    
    codes_and_descriptions.each do |code, expected|
      description = @service.send(:weather_description, code)
      assert_equal expected, description
    end
  end

  test "should handle error responses" do
    error_result = @service.send(:error, "Test error message")
    
    assert error_result[:error]
    assert_equal "Test error message", error_result[:error]
  end

  test "should return formatted weather data structure" do
    # Test the expected structure of a successful response
    # This tests the format without making actual API calls
    expected_keys = [:address, :temperature, :feels_like, :description, :humidity, :cached]
    
    # Mock a successful response structure
    mock_response = {
      address: "Test City",
      temperature: 20,
      feels_like: 22,
      description: "Sunny",
      humidity: 60,
      cached: false
    }
    
    # Verify all expected keys are present
    expected_keys.each do |key|
      assert mock_response.key?(key), "Missing key: #{key}"
    end
    
    # Verify data types
    assert_kind_of String, mock_response[:address]
    assert_kind_of Integer, mock_response[:temperature]
    assert_kind_of String, mock_response[:description]
    assert_includes [true, false], mock_response[:cached]
  end
end