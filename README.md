# Weather Forecast App
A Ruby on Rails application that allows users to retrieve a weather forecast for a given address. The app converts the 
address into geographic coordinates and fetches weather data from the National Weather Service API, caching results for 
faster subsequent requests.

---

## Features
- Input full address (street, city, state, zip) and get a weather forecast.
- Fetches weather forecast from the National Weather Service API.
- Caches forecast data in Redis for 30 minutes to improve performance.
- Responsive, user-friendly HTML forms with client-side validation for ZIP codes.
- Supports both HTML and JSON responses.

---

## Requirements
- Ruby 3.4.4
- Rails 8.0.x
- SQLite3 (development)
- Redis (for caching)
- Node.js and Yarn (for Webpacker assets)

---

## Setup
1. Clone the repository:

```bash
git clone https://github.com/your-username/teksystems-weather-app.git
cd teksystems-weather-app
```

2. Install dependencies:

```bash
bundle install
yarn install
```

3. Set up the database:

```bash
rails db:create db:migrate
```

4. Start Redis (required for caching):

```bash
redis-server
```

5. Start the Rails server:

```bash
rails server
```

6. Open your browser and navigate to: http://localhost:3000/weather

## Usage
1. Enter your full address, or just a ZIP code as that is all that is required, in the form.

2. Click Get Forecast to retrieve the weather forecast.

3. The forecast will be cached for 30 minutes for the same ZIP code.

## Directory Structure Highlights
app/assets/stylesheets — CSS for styling forms and forecast display.

app/services/geolocation — Location and Nominatim API services.

app/services/weather — WeatherService and NationalWeatherService.

app/views/weather — ERB templates for home and forecast pages.

public/favicon.ico — Application favicon.

## Testing
This project uses RSpec for unit testing and service testing:

```bash
bundle exec rspec
```

## Notes
ZIP codes are validated on the front-end (HTML5 validation) as well as the back-end.

Favicons are served from the /public directory.

Forecast periods are displayed in a uniform card layout using CSS flexbox.

Redis caching improves performance and reduces API calls to external services.

## License
This project is licensed under the MIT License.

## Contact
Developer: Etan Mizrahi-Shalom
Email: etanms@gmail.com
