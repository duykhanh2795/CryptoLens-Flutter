double readDouble(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int readInt(Object? value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

String readString(Object? value, {String fallback = ''}) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return fallback;
  return text;
}

DateTime readDateTime(Object? value, {DateTime? fallback}) {
  if (value is DateTime) return value;
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  return parsed ?? fallback ?? DateTime.now();
}

Map<String, Object?> readObjectMap(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return value.cast<String, Object?>();
  return const {};
}

List<Object?> readObjectList(Object? value) {
  if (value is List<Object?>) return value;
  if (value is List) return value.cast<Object?>();
  return const [];
}

T? readEnum<T extends Enum>(Iterable<T> values, Object? raw) {
  final name = raw?.toString();
  if (name == null) return null;
  final normalized = name.replaceAll('_', '').toLowerCase();
  for (final value in values) {
    if (value.name == name ||
        value.toString() == name ||
        value.name.replaceAll('_', '').toLowerCase() == normalized) {
      return value;
    }
  }
  return null;
}
