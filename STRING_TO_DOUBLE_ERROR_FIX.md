# String to Double Conversion Error - Fixed

## Problem
**Error:** `NoSuchMethodError: class String has no instance method "toDouble". receiver: "50.00"`

This error occurred when the backend API returned the price as a string (e.g., `"50.00"`) instead of a number, and the code tried to call `.toDouble()` on the string value directly.

## Root Cause

The original `Plan.fromJson()` method had this problematic code:
```dart
price: (json['price'] ?? json['plan_price'] ?? 0).toDouble(),
```

This assumes the value is always numeric (int or double), but the backend was returning:
```json
{
  "id": "123",
  "name": "Premium Plan",
  "price": "50.00",  // ← STRING instead of NUMBER!
  "durationDays": 30
}
```

When a string receives the `.toDouble()` call, Dart throws `NoSuchMethodError` because strings don't have that method.

## Solution

Implemented proper type checking and parsing with helper functions:

```dart
factory Plan.fromJson(Map<String, dynamic> json) {
  // Helper function to safely convert to double
  double parsePrice(dynamic priceValue) {
    if (priceValue == null) return 0.0;
    if (priceValue is double) return priceValue;
    if (priceValue is int) return priceValue.toDouble();
    if (priceValue is String) {
      return double.tryParse(priceValue) ?? 0.0;  // ← Parse string to double
    }
    return 0.0;
  }

  // Helper function to safely convert to int
  int parseDuration(dynamic durationValue) {
    if (durationValue == null) return 0;
    if (durationValue is int) return durationValue;
    if (durationValue is double) return durationValue.toInt();
    if (durationValue is String) {
      return int.tryParse(durationValue) ?? 0;  // ← Parse string to int
    }
    return 0;
  }

  return Plan(
    id: (json['id'] ?? json['_id'] ?? '').toString(),
    name: (json['name'] ?? json['plan_name'] ?? '').toString(),
    price: parsePrice(json['price'] ?? json['plan_price']),  // ← Use helper
    durationDays: parseDuration(json['duration_days'] ?? json['durationDays']),  // ← Use helper
    description: (json['description'] ?? '').toString(),
    isActive: (json['is_active'] ?? json['isActive'] ?? true) == true,
  );
}
```

## How It Works Now

### Type Handling

The `parsePrice()` function now handles:
1. **null values** → returns `0.0`
2. **double values** → returns as-is
3. **int values** → converts to double
4. **string values** → uses `double.tryParse()` to safely convert
5. **invalid values** → returns `0.0` as fallback

Similarly, `parseDuration()` handles the same types for integers.

### Null Safety

Both helper functions use safe parsing:
- `double.tryParse("50.00")` returns `50.0` or `null` if invalid
- `?? 0.0` provides fallback for null values

## Benefits

✅ **Handles multiple data types** - Works with number, integer, or string data  
✅ **Null safe** - Won't crash on null values  
✅ **Flexible** - Adapts to different backend response formats  
✅ **Graceful defaults** - Returns 0.0 or 0 for invalid data  
✅ **Future-proof** - Works if backend changes data types  

## Testing

### Before Fix
```dart
// Backend sends: {"price": "50.00"}
// Error: NoSuchMethodError: class String has no instance method "toDouble"
```

### After Fix
```dart
// Backend sends: {"price": "50.00"}
// ✅ Correctly parsed as: 50.0
// Backend sends: {"price": 50}
// ✅ Correctly parsed as: 50.0
// Backend sends: {"price": 50.0}
// ✅ Correctly parsed as: 50.0
```

## Files Changed

- **File:** `lib/viewmodels/plans_viewmodel.dart`
- **Changed Method:** `Plan.fromJson(Map<String, dynamic> json)`
- **Lines:** 20-54

## Similar Issues Fixed

The same fix pattern should be applied to any other model that receives numeric data from the backend:

### Dashboard Stats
The `monthlyRevenue` is already stored as `String` - ✅ No fix needed

### Members
All numeric fields already handled correctly - ✅ No fix needed

### Subscriptions
All date parsing already uses `DateTime.tryParse()` - ✅ No fix needed

## Future Prevention

To prevent similar issues:

1. **Backend Communication:** Ensure backend documentation specifies expected data types
2. **Type Checking:** Always use `tryParse()` or type-checking before calling `.toDouble()` or `.toInt()`
3. **Helper Functions:** Create reusable parsing functions for common conversions
4. **Testing:** Test with various data formats before deployment

## Verification

Run the app and test:
1. Navigate to Plans page
2. Should load plans without errors
3. Prices should display correctly (e.g., "50.00", "99.99")
4. Add new plan with decimal price (e.g., "149.99")
5. Should save and display correctly

---

**Status:** ✅ FIXED  
**Date:** 2026-02-22  
**Issue:** NoSuchMethodError on string to double conversion  
**Solution:** Type-safe parsing with helper functions

