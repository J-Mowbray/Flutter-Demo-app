# Imagineear LTD Flutter technical test submission - Jamie Mowbray
A simple weather app that shows a 7 day forecast and the current weather using the https://open-meteo.com/ open source weather app.

## Technical Notes

### Constants Usage

The project includes an `AppConstants` class that centralizes important configuration values like API endpoints, UI dimensions, and weather thresholds. However, these constants are not consistently used throughout the codebase.

Future development should prioritize refactoring to use these constants instead of hardcoded values for:

- API base URLs
- Weather condition thresholds
- UI padding and border radius values
- Forecast days/hours configuration
- Temperature unit representations

This will improve maintainability by ensuring changes to these values only need to be made in one place.
