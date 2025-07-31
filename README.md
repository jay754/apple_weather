# Weather App

A simple Rails application that fetches and displays weather information for any location.

## Features

- **Weather Lookup**: Enter any city or address to get current weather conditions

## How to Run

1. **Start Redis:**
   ```bash
   redis-server
   ```

2. **Start the app:**
   ```bash
   bin/rails server
   ```

3. **Open your browser:**
   Navigate to http://localhost:3000

## Usage

1. Enter a city name or address (e.g., "New York", "London", "Tokyo")
2. Click "Get Weather"
3. View the current weather conditions
4. Subsequent requests for the same location will show cached data for 30 minutes

## Testing

Run the test suite:
```bash
# All tests
rails test

# Controller tests only
rails test test/controllers/

# Service tests only
rails test test/services/
```