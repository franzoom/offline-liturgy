# DataLoader Architecture - offline_liturgy

## Overview

The `offline_liturgy` package uses an abstract architecture to load JSON files, keeping the Dart code pure while being compatible with Flutter.

## File Structure

```
offline_liturgy/
├── lib/
│   ├── tools/
│   │   └── data_loader.dart          # Abstract interface + FileSystemDataLoader
│   ├── offices/
│   │   ├── compline_detection.dart   # Uses DataLoader
│   │   └── compline.dart             # Uses DataLoader
│   └── main.dart                     # Usage example with FileSystemDataLoader
├── assets/
│   └── calendar_data/                # 700 JSON files
└── pubspec.yaml

aelf/ (your Flutter app)
├── lib/
│   └── services/
│       └── flutter_data_loader.dart  # Flutter implementation
└── pubspec.yaml
```

## 📦 In the `offline_liturgy` package

### 1. Declare assets in `pubspec.yaml`

```yaml
name: offline_liturgy
description: Liturgy data models and parsers

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  # No Flutter dependencies!

flutter:
  assets:
    - assets/calendar_data/special_days/
    - assets/calendar_data/sanctoral/
    - assets/calendar_data/ferial_days/
    - assets/calendar_data/commons/
    - assets/locations.json
```

### 2. Usage for pure Dart

```dart
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:offline_liturgy/tools/data_loader.dart';

Future<void> main() async {
  final dataLoader = FileSystemDataLoader();
  
  Calendar calendar = getCalendar(Calendar(), DateTime.now(), 'lyon');
  
  final complines = await complineDefinitionResolution(
    calendar, 
    DateTime.now(), 
    dataLoader
  );
  
  // Use the complines...
}
```

## 📱 In the Flutter app `aelf`

### 1. Create `lib/services/flutter_data_loader.dart`

Copy the content from the provided `flutter_data_loader.dart` file.

### 2. Usage in the app

```dart
import 'package:offline_liturgy/offline_liturgy.dart';
import 'services/flutter_data_loader.dart';

class CompliesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, ComplineDefinition>>(
      future: _loadComplines(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final complines = complineTextCompilation(snapshot.data!);
          // Display complines...
        }
        return CircularProgressIndicator();
      },
    );
  }
  
  Future<Map<String, ComplineDefinition>> _loadComplines() async {
    final dataLoader = FlutterDataLoader();
    final calendar = getCalendar(Calendar(), DateTime.now(), 'lyon');
    
    return await complineDefinitionResolution(
      calendar,
      DateTime.now(),
      dataLoader,
    );
  }
}
```

## 🔑 Key Points

### ✅ Advantages of this architecture

1. **Pure Dart package**: No Flutter dependency in the code
2. **Flexible**: Create other implementations if needed (HTTP, cache, etc.)
3. **Performance**: Lazy loading - loads only necessary files
4. **Maintainable**: Clear separation of concerns
5. **Easy to use**: Simple interface for different contexts

### 🚫 What NOT to do

```dart
// ❌ NEVER DO THIS in the package
import 'dart:io';

final file = File('./assets/file.json'); // Doesn't work with Flutter!
```

```dart
// ❌ NEVER DO THIS in the package
import 'package:flutter/services.dart'; // Creates a Flutter dependency!
```

### ✅ What to do instead

```dart
// ✅ Always use the DataLoader
Future<String> loadData(DataLoader dataLoader) async {
  final content = await dataLoader.loadJson('path/to/file.json');
  // Parse JSON...
}
```

## 📝 Migrating existing code

If you have other files using `File()`, follow this pattern:

### Before
```dart
String _searchInJsonFile(String filePath) {
  final file = File(filePath);
  if (!file.existsSync()) return '';
  final content = file.readAsStringSync();
  return content;
}
```

### After
```dart
Future<String> _searchInJsonFile(String relativePath, DataLoader dataLoader) async {
  try {
    final content = await dataLoader.loadJson(relativePath);
    if (content.isEmpty) return '';
    return content;
  } catch (e) {
    return '';
  }
}
```

## 🧪 Unit Testing

Create a mock for testing:

```dart
class MockDataLoader implements DataLoader {
  final Map<String, String> _mockData;
  
  MockDataLoader(this._mockData);
  
  @override
  Future<String> loadJson(String relativePath) async {
    return _mockData[relativePath] ?? '';
  }
}

// In your tests
void main() {
  test('compline detection works', () async {
    final mockLoader = MockDataLoader({
      'calendar_data/special_days/immaculate_conception.json': 
        '{"celebrationTitle": "Immaculate Conception"}'
    });
    
    final result = await getFrenchComplineDescription(
      'immaculate_conception',
      mockLoader,
    );
    
    expect(result, 'Complies de Immaculate Conception');
  });
}
```

## 🎯 Summary

- **`offline_liturgy` package**: Uses the `DataLoader` interface
- **Pure Dart usage**: Use `FileSystemDataLoader` (reads from file system)
- **Flutter app**: Use `FlutterDataLoader` (reads from rootBundle)
- **Unit tests**: Create mocks of `DataLoader`

This architecture keeps your package clean, flexible, and compatible with Flutter! 🎉

## 📋 Implementation Checklist

### In offline_liturgy package:
- [ ] Copy `data_loader.dart` to `lib/tools/`
- [ ] Update `compline_detection.dart` with the refactored version
- [ ] Update `compline.dart` with the refactored version
- [ ] Update `main.dart` with the refactored version
- [ ] Add `flutter:` section to `pubspec.yaml`
- [ ] Add `DataLoader` parameter to any other functions using `File()`

### In Flutter app (aelf):
- [ ] Create `lib/services/flutter_data_loader.dart`
- [ ] Update code to use `FlutterDataLoader`
- [ ] Pass `dataLoader` to all functions that need it
- [ ] Test that JSON files load correctly

## 🔄 Migration Pattern

For every function that loads JSON:

1. **Add DataLoader parameter**:
   ```dart
   // Before
   Future<Data> loadData() async { ... }
   
   // After
   Future<Data> loadData(DataLoader dataLoader) async { ... }
   ```

2. **Replace File() with dataLoader.loadJson()**:
   ```dart
   // Before
   final file = File(path);
   final content = file.readAsStringSync();
   
   // After
   final content = await dataLoader.loadJson(relativePath);
   ```

3. **Make function async if not already**:
   ```dart
   // Before
   String getData() { ... }
   
   // After
   Future<String> getData(DataLoader dataLoader) async { ... }
   ```

4. **Update all callers** to pass the dataLoader and use await

## 💡 Tips

- Keep the DataLoader instance at the top level of your app and pass it down
- You can create a cached version of DataLoader that stores loaded files in memory
- For large apps, consider dependency injection for the DataLoader
- The same pattern can be extended for other resources (images, audio files, etc.)
