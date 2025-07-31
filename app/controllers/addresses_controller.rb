class AddressesController < ApplicationController
  def new
    @weather_data = nil
  end

  def create
    Rails.logger.info "=== ADDRESS CONTROLLER: All params: #{params.inspect}"
    @address = params[:address]
    Rails.logger.info "=== ADDRESS CONTROLLER: Received address: '#{@address}'"
    Rails.logger.info "=== ADDRESS CONTROLLER: Address present?: #{@address.present?}"
    
    if @address.present?
      Rails.logger.info "=== ADDRESS CONTROLLER: Creating WeatherService"
      weather_service = WeatherService.new(@address)
      
      Rails.logger.info "=== ADDRESS CONTROLLER: Calling get_forecast"
      @weather_data = weather_service.get_forecast
      
      Rails.logger.info "=== ADDRESS CONTROLLER: Weather data received: #{@weather_data}"
      
      if @weather_data[:error]
        Rails.logger.error "=== ADDRESS CONTROLLER: Error in weather data: #{@weather_data[:error]}"
        flash[:alert] = @weather_data[:error]
      else
        Rails.logger.info "=== ADDRESS CONTROLLER: Success! Weather data retrieved"
        flash[:notice] = "Weather data retrieved successfully!"
      end
      
      render :new
    else
      Rails.logger.warn "=== ADDRESS CONTROLLER: No address provided"
      flash[:alert] = "Please enter an address"
      render :new
    end
  end
end