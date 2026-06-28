import 'package:latlong2/latlong.dart';

/// Simple global state to share data between tabs without heavy state management.
class AppState {
  static List<LatLng>? activeRoutePolyline;
  static bool hasActiveRoute = false;

  static void setActivePolyline(List<LatLng> polyline) {
    activeRoutePolyline = polyline;
    hasActiveRoute = true;
  }

  static void clear() {
    activeRoutePolyline = null;
    hasActiveRoute = false;
  }
}
