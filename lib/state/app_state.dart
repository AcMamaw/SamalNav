import 'package:latlong2/latlong.dart';

/// Simple global state to share data between tabs without heavy state management.
class AppState {
  static List<LatLng>? activeRoutePolyline;
  static List<List<LatLng>> activeRouteSegments = [];
  static bool hasActiveRoute = false;

  static void setActivePolyline(List<LatLng> polyline) {
    setActiveRouteSegments([polyline]);
  }

  static void setActiveRouteSegments(List<List<LatLng>> segments) {
    activeRouteSegments = segments.map((segment) => List<LatLng>.from(segment)).toList();
    activeRoutePolyline = activeRouteSegments.expand((segment) => segment).toList();
    hasActiveRoute = activeRoutePolyline!.isNotEmpty;
  }

  static void clear() {
    activeRoutePolyline = null;
    activeRouteSegments = [];
    hasActiveRoute = false;
  }
}
