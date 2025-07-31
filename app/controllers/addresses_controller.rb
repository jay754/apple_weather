class AddressesController < ApplicationController
  def new
    @weather_data = nil
  end

  def create
    @address = sanitized_address
    
    if @address.blank?
      handle_empty_address
    else
      fetch_weather_data
    end
    
    render :new
  end

  private

  def sanitized_address
    params[:address]&.strip
  end

  def handle_empty_address
    flash[:alert] = "Please enter an address"
    Rails.logger.info "Address submission failed: No address provided"
  end

  def fetch_weather_data
    Rails.logger.info "Fetching weather data for: #{@address}"
    
    @weather_data = WeatherService.new(@address).get_forecast
    
    if weather_request_successful?
      handle_successful_request
    else
      handle_failed_request
    end
  rescue StandardError => e
    handle_service_error(e)
  end

  def weather_request_successful?
    @weather_data && !@weather_data[:error]
  end

  def handle_successful_request
    flash[:notice] = "Weather data retrieved successfully!"
    log_cache_status
  end

  def handle_failed_request
    flash[:alert] = @weather_data[:error]
    Rails.logger.warn "Weather request failed for #{@address}: #{@weather_data[:error]}"
  end

  def handle_service_error(error)
    flash[:alert] = "Unable to fetch weather data. Please try again."
    Rails.logger.error "Weather service error for #{@address}: #{error.message}"
    @weather_data = nil
  end

  def log_cache_status
    status = @weather_data[:cached] ? "cached" : "live"
    Rails.logger.info "Weather data retrieved for #{@address} (#{status})"
  end
end