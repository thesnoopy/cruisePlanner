
import 'route_item.dart';
import 'sea_day_item.dart';
import 'port_call_item.dart';

RouteItem routeItemFromMap(Map<String, dynamic> map) {
  switch (map['type']) {
    case 'sea':
      return SeaDayItem.fromMap(map);
    case 'port':
      return PortCallItem.fromMap(map);
    default:
      throw ArgumentError('Unknown route item type: ${map['type']}');
  }
}
