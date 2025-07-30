class AddressesController < ApplicationController
  def new
  end

  def create
    @address = params[:address]
    
    if @address.present?
      flash[:notice] = "Address received: #{@address}"
      redirect_to new_address_path
    else
      flash[:alert] = "Please enter an address"
      render :new
    end
  end
end