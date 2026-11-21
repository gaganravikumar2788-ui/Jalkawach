# JalKawach

JalKawach is a Flutter application for flood disaster preparedness and emergency awareness in India. It brings real-time flood-risk forecasting, CWC hydrological telemetry, live weather, hazard maps, NDMA emergency alerts, verified relief shelters, safety guidelines, and emergency contacts into a unified interface.

## Demo Data

The app runs without a backend using simulated demonstration data by default. This data is not a live forecast or emergency alert. The client includes a FastAPI integration layer; a compatible backend can be connected via `AppConstants.defaultApiBaseUrl`.

## Run Locally

Install the Flutter SDK, then from the project directory run:

```sh
flutter pub get
flutter run -d chrome
```

To run on another available target, list devices with `flutter devices` and replace `chrome` with its device ID. Windows desktop builds may require enabling Windows Developer Mode to allow symlinks.

## Test

```sh
flutter test
```
