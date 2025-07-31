# Weather App

A simple Rails application that fetches and displays weather information for any location.

## Features

- **Weather Lookup**: Enter any city or address to get current weather conditions

## Technology Stack

- **Ruby on Rails 8.0**
- **SQLite** database
- **Redis** for caching
- **Open-Meteo API** for weather data
- **Turbo & Stimulus** for frontend interactions

## Usage

1. Enter a city name or address (e.g., "New York", "London", "Tokyo")
2. Click "Get Weather"
3. View the current weather conditions
4. Subsequent requests for the same location will show cached data for 30 minutes

## API Integration

The app uses the [Open-Meteo API](https://open-meteo.com/):
- **Geocoding API**: Converts location names to coordinates
- **Weather API**: Fetches current weather conditions
- **No API key required**: Free and open service