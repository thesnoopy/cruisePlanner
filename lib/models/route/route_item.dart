
import '../identifiable.dart';

abstract class RouteItem extends Identifiable {
  @override
  String get id;
  DateTime get date;
  String get type; // 'sea' | 'port'
  Map<String, dynamic> toMap();
}
