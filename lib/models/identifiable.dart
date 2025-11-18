
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

abstract class Identifiable extends Equatable {
  String get id;
  static String newId() => const Uuid().v4();
}
