DateTime? readNullableUtcDateTime(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is! String || value.isEmpty) {
    return null;
  }

  final parsed = DateTime.tryParse(value);
  return parsed?.toUtc();
}

String? writeNullableUtcDateTime(DateTime? value) {
  return value?.toUtc().toIso8601String();
}
