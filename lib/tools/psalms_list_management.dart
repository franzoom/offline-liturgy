/// merging function for psalm lists, used when the psalm called are not
/// the default ones.
Map<int, Map<String, List<String>>> mergePsalms(
  Map<int, Map<String, List<String>>> base,
  Map<int, Map<String, List<String>>> additions,
) {
  // We create a deep-ish copy of the base map to avoid side effects
  final result = Map<int, Map<String, List<String>>>.from(
    base.map(
        (key, value) => MapEntry(key, Map<String, List<String>>.from(value))),
  );

  for (final weekEntry in additions.entries) {
    final week = weekEntry.key;
    final days = weekEntry.value;

    // Use putIfAbsent to initialize the week map if it doesn't exist
    final baseDays = result.putIfAbsent(week, () => {});

    for (final dayEntry in days.entries) {
      // Overwrite the specific day with the new list of psalms
      baseDays[dayEntry.key] = List<String>.from(dayEntry.value);
    }
  }

  return result;
}
