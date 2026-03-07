String generateUniqueId([DateTime? timestamp]) {
  // TODO(wim): use a uuid for this to be truly unique
  timestamp ??= DateTime.now();
  final buffer = StringBuffer()
    ..write(timestamp.year)
    ..write(timestamp.month.toString().padLeft(2, '0'))
    ..write(timestamp.day.toString().padLeft(2, '0'))
    ..write(timestamp.hour.toString().padLeft(2, '0'))
    ..write(timestamp.minute.toString().padLeft(2, '0'))
    ..write(timestamp.second.toString().padLeft(2, '0'));

  return buffer.toString();
}
