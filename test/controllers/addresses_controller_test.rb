# test/controllers/addresses_controller_test.rb
require "test_helper"

class AddressesControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_address_path
    assert_response :success
    assert_select "h1", "Weather Forecast"
    assert_select "input[name='address']"
  end

  test "should handle root path" do
    get root_path
    assert_response :success
    assert_select "h1", "Weather Forecast"
  end

  test "should show error for empty address" do
    post addresses_path, params: { address: "" }
    assert_response :success
    assert_select "div", text: /Please enter an address/
  end

  test "should show error for whitespace address" do
    post addresses_path, params: { address: "   " }
    assert_response :success
    assert_select "div", text: /Please enter an address/
  end

  test "should display weather data on successful request" do
    # Stub the weather service at the class level
    WeatherService.define_method(:get_forecast) do
      {
        address: "New York",
        temperature: 25,
        feels_like: 25,
        description: "Clear sky",
        humidity: 65,
        cached: false
      }
    end
    
    post addresses_path, params: { address: "New York" }
    
    assert_response :success
    assert_select "h2", text: /Weather for New York/
    assert_select "h3", text: "25°C"
    
    # Restore original method
    WeatherService.send(:remove_method, :get_forecast)
    WeatherService.send(:alias_method, :get_forecast, :original_get_forecast) if WeatherService.method_defined?(:original_get_forecast)
  end

  test "should show error message from weather service" do
    WeatherService.define_method(:get_forecast) do
      { error: "Location not found" }
    end
    
    post addresses_path, params: { address: "InvalidLocation" }
    
    assert_response :success
    assert_select "div", text: /Location not found/
    
    # Cleanup
    WeatherService.send(:remove_method, :get_forecast)
  end

  test "should display cached indicator for cached data" do
    WeatherService.define_method(:get_forecast) do
      {
        address: "London",
        temperature: 18,
        description: "Partly cloudy",
        humidity: 70,
        cached: true
      }
    end
    
    post addresses_path, params: { address: "London" }
    
    assert_response :success
    assert_select "span", text: "📋 CACHED"
    
    # Cleanup
    WeatherService.send(:remove_method, :get_forecast)
  end

  test "should display live indicator for fresh data" do
    WeatherService.define_method(:get_forecast) do
      {
        address: "Paris",
        temperature: 22,
        description: "Rain",
        humidity: 85,
        cached: false
      }
    end
    
    post addresses_path, params: { address: "Paris" }
    
    assert_response :success
    assert_select "span", text: "🌐 LIVE"
    
    # Cleanup
    WeatherService.send(:remove_method, :get_forecast)
  end

  test "should handle missing address parameter" do
    post addresses_path, params: {}
    
    assert_response :success
    assert_select "div", text: /Please enter an address/
  end

  test "should not display weather data when error occurs" do
    WeatherService.define_method(:get_forecast) do
      { error: "Weather data not available" }
    end
    
    post addresses_path, params: { address: "Mars" }
    
    assert_response :success
    assert_select "h2", text: /Weather for/, count: 0
    
    # Cleanup
    WeatherService.send(:remove_method, :get_forecast)
  end
end