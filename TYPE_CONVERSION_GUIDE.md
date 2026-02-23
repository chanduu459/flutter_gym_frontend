# Type Conversion Best Practices - Dart/Flutter

## Issue Overview

When working with JSON data from APIs, the backend might return numeric values as:
- Numbers: `42`, `3.14`
- Strings: `"42"`, `"3.14"`
- Different types than expected

## Pattern: Safe Type Conversion

### ❌ WRONG - Can Crash
```dart
// DANGER: Crashes if data is String
int age = json['age'].toInt();  // NoSuchMethodError if json['age'] is "25"
double price = json['price'].toDouble();  // NoSuchMethodError if json['price'] is "50.00"
```

### ✅ CORRECT - Type Safe
```dart
// Pattern 1: Direct type conversion
int age = (json['age'] as int?) ?? 0;
double price = (json['price'] as double?) ?? 0.0;

// Pattern 2: Using tryParse (for strings)
int age = int.tryParse(json['age'].toString()) ?? 0;
double price = double.tryParse(json['price'].toString()) ?? 0.0;

// Pattern 3: Helper function (BEST for complex logic)
double parsePrice(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
```

## Common Conversions

### String to Int
```dart
int parseInt(dynamic value, {int defaultValue = 0}) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}
```

### String to Double
```dart
double parseDouble(dynamic value, {double defaultValue = 0.0}) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}
```

### String to Bool
```dart
bool parseBool(dynamic value, {bool defaultValue = false}) {
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true' || value == '1';
  if (value is int) return value != 0;
  return defaultValue;
}
```

### String to DateTime
```dart
DateTime parseDateTime(dynamic value, {DateTime? defaultValue}) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? defaultValue ?? DateTime.now();
  return defaultValue ?? DateTime.now();
}
```

## Applied Example from Plans Page

```dart
factory Plan.fromJson(Map<String, dynamic> json) {
  // Define helper functions once
  double parsePrice(dynamic priceValue) {
    if (priceValue == null) return 0.0;
    if (priceValue is double) return priceValue;
    if (priceValue is int) return priceValue.toDouble();
    if (priceValue is String) {
      return double.tryParse(priceValue) ?? 0.0;
    }
    return 0.0;
  }

  int parseDuration(dynamic durationValue) {
    if (durationValue == null) return 0;
    if (durationValue is int) return durationValue;
    if (durationValue is double) return durationValue.toInt();
    if (durationValue is String) {
      return int.tryParse(durationValue) ?? 0;
    }
    return 0;
  }

  // Use helpers in fromJson
  return Plan(
    id: (json['id'] ?? json['_id'] ?? '').toString(),
    name: (json['name'] ?? json['plan_name'] ?? '').toString(),
    price: parsePrice(json['price'] ?? json['plan_price']),
    durationDays: parseDuration(json['duration_days'] ?? json['durationDays']),
    description: (json['description'] ?? '').toString(),
    isActive: (json['is_active'] ?? json['isActive'] ?? true) == true,
  );
}
```

## Tips & Tricks

### 1. Always Check for Null First
```dart
// Safe: Handles null gracefully
double parsePrice(dynamic value) {
  if (value == null) return 0.0;  // ← Check null first
  if (value is double) return value;
  // ...
}
```

### 2. Use Null Coalescing Operator
```dart
// Get first non-null field
price: parsePrice(json['price'] ?? json['plan_price'] ?? json['amount'])
```

### 3. Default Values
```dart
// Always provide sensible defaults
age: parseInt(json['age'], defaultValue: 0),
price: parseDouble(json['price'], defaultValue: 99.99),
```

### 4. Field Name Variations
```dart
// Handle different naming conventions
name: (json['name'] ?? json['plan_name'] ?? json['planName'] ?? '').toString(),
price: parsePrice(json['price'] ?? json['plan_price'] ?? json['planPrice']),
```

### 5. toString() for Safety
```dart
// Always convert to string before displaying
description: (json['description'] ?? '').toString(),
```

## Reusable Parser Library

Create a utility file: `lib/utils/json_parsers.dart`

```dart
class JsonParsers {
  static int parseInt(dynamic value, {int defaultValue = 0}) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static double parseDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static bool parseBool(dynamic value, {bool defaultValue = false}) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    if (value is int) return value != 0;
    return defaultValue;
  }

  static DateTime parseDateTime(dynamic value, {DateTime? defaultValue}) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? defaultValue ?? DateTime.now();
    return defaultValue ?? DateTime.now();
  }

  static String parseString(dynamic value, {String defaultValue = ''}) {
    if (value is String) return value;
    return defaultValue;
  }
}
```

Usage:
```dart
import '../utils/json_parsers.dart';

factory Plan.fromJson(Map<String, dynamic> json) {
  return Plan(
    price: JsonParsers.parseDouble(json['price'] ?? json['plan_price']),
    durationDays: JsonParsers.parseInt(json['duration_days'] ?? json['durationDays']),
  );
}
```

## API Response Formats Handled

The safe parsing approach handles all these formats:

```json
// Format 1: Proper types (ideal)
{"price": 50.00, "durationDays": 30}

// Format 2: String numbers (common)
{"price": "50.00", "durationDays": "30"}

// Format 3: Mixed
{"price": "50.00", "durationDays": 30}

// Format 4: Integers for decimals
{"price": 5000, "durationDays": 30}  // Could mean $50.00 (cents)

// Format 5: With nulls
{"price": null, "durationDays": null}
```

All handled gracefully with proper defaults!

## Testing Strategies

### Test All Type Conversions
```dart
test('Plan.fromJson handles string price', () {
  final json = {'price': '50.00', 'durationDays': '30'};
  final plan = Plan.fromJson(json);
  expect(plan.price, 50.0);
  expect(plan.durationDays, 30);
});

test('Plan.fromJson handles null values', () {
  final json = {'price': null, 'durationDays': null};
  final plan = Plan.fromJson(json);
  expect(plan.price, 0.0);
  expect(plan.durationDays, 0);
});

test('Plan.fromJson handles number types', () {
  final json = {'price': 50, 'durationDays': 30};
  final plan = Plan.fromJson(json);
  expect(plan.price, 50.0);
  expect(plan.durationDays, 30);
});
```

---

**Remember:** Type safety prevents `NoSuchMethodError` and makes your app more robust!

