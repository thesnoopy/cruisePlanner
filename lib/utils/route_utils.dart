// lib/utils/route_utils.dart
import '../models/route_item.dart';

DateTime _asDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

List<RouteItem> sortRoute(List<RouteItem> route) {
  final copy = [...route];
  copy.sort((a, b) => a.date.compareTo(b.date));
  return copy;
}

RouteItem? routeForToday(DateTime now, List<RouteItem> route) {
  final today = _asDay(now);
  for (final r in route) {
    if (_asDay(r.date) == today) return r;
  }
  return null;
}

RouteItem? routeForTomorrow(DateTime now, List<RouteItem> route) {
  final tomorrow = _asDay(now).add(const Duration(days: 1));
  for (final r in route) {
    if (_asDay(r.date) == tomorrow) return r;
  }
  return null;
}
