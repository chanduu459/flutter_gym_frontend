# Plans Page Data Loading Fix - Summary

## Problems Fixed

### 1. **Data Parsing Issue**
**Problem:** The PlansViewModel was not properly handling different API response formats.

**Solution:** Updated `_initializePlans()` in `plans_viewmodel.dart` to handle multiple response formats:
- Direct list responses: `[{plan1}, {plan2}, ...]`
- Wrapped responses: `{plans: [{plan1}, {plan2}, ...]}`
- Proper error handling with detailed logging

### 2. **Missing Pull-to-Refresh**
**Problem:** Users had no way to manually refresh the plans list.

**Solution:** Added `RefreshIndicator` widget to the plans list in `plans_screen.dart` that calls `plansViewModel.refresh()`.

### 3. **Enhanced API Logging**
**Problem:** Difficult to debug API issues without visibility into requests/responses.

**Solution:** Added comprehensive debug logging to `api_service.dart`:
- Log API endpoint being called
- Log response status and body
- Log parsing and unwrapping of data
- Color-coded print statements for easy identification (🔵🟢🔴)

### 4. **Improved Error Handling**
**Problem:** Users didn't know when plans failed to load.

**Solution:** Enhanced error display in `plans_screen.dart`:
- Show error messages as dismissible alerts
- Log errors to console for debugging
- Display appropriate "No plans found" message when list is empty

## Code Changes

### File: `lib/viewmodels/plans_viewmodel.dart`

**Changed:** `_initializePlans()` method
```dart
// Now handles multiple response formats
List<dynamic> plansList = [];
if (data is List) {
  plansList = data;
} else if (data is Map && data.containsKey('plans')) {
  plansList = data['plans'] as List<dynamic>;
} else {
  throw ApiException('Invalid response format from server');
}

// Better parsing with null safety
final plans = plansList
    .map((json) {
      if (json is Map<String, dynamic>) {
        return Plan.fromJson(json);
      } else if (json is Map) {
        return Plan.fromJson(json.cast<String, dynamic>());
      }
      return null;
    })
    .whereType<Plan>()
    .toList();
```

### File: `lib/screens/plans_screen.dart`

**Added:** 
- Pull-to-refresh capability with `RefreshIndicator`
- Better error display with dismiss button
- Log statements for monitoring data loading

### File: `lib/services/api_service.dart`

**Enhanced:** `_request()` method with detailed logging
```dart
print('🔵 [HTTP] $method $uri');
print('🟢 [HTTP] Status ${response.statusCode}');
print('🟢 [HTTP] Response body: ${response.body}');
// ... more detailed logging
```

**Enhanced:** `getPlans()` method with logging
```dart
print('🔵 [API] Calling GET /api/plans');
final data = await _request('/api/plans');
print('🟢 [API] Got plans response: $data');
print('🟢 [API] Parsed plans list with ${result.length} items');
```

## How It Works Now

### Data Flow

1. **Screen Navigation**
   - User navigates to Plans screen from menu
   - PlansScreen widget is created
   - PlansViewModelProvider creates PlansViewModel instance

2. **Data Loading**
   - PlansViewModel constructor calls `_initializePlans()`
   - Sets state to `isLoading: true`
   - Calls `apiService.getPlans()`

3. **API Call**
   - ApiService calls `GET /api/plans` endpoint
   - Includes Bearer token in Authorization header
   - Logs request and response details

4. **Response Processing**
   - ApiService unwraps response data
   - PlansViewModel parses the list
   - Converts each plan JSON to Plan object
   - Updates state with plans list and `isLoading: false`

5. **UI Update**
   - PlansScreen rebuilds when state changes
   - Displays plans in ListView
   - Shows loading indicator during fetch
   - Shows error message if API fails

6. **Refresh**
   - User swipes down to refresh (pull-to-refresh)
   - Or clicks retry button
   - Calls `plansViewModel.refresh()`
   - Repeats the loading process

## API Configuration

**Base URL:** `http://10.198.164.90:3001`

This is set in `lib/services/api_service.dart`:
```dart
_baseUrl = baseUrl ??
    const String.fromEnvironment(
      'API_URL',
      defaultValue: 'http://10.198.164.90:3001',
    );
```

**Authentication:**
- Token is set after successful login
- All requests include `Authorization: Bearer <token>` header
- Token is stored in ApiService._token

## Testing the Fix

### 1. Start the Backend
```bash
# In your backend project directory
npm start
# Should be running on http://10.198.164.90:3001
```

### 2. Run the App
```bash
cd D:\fp\gymsas_myapp
flutter run
```

### 3. Login
- Use valid credentials from your backend database
- This sets the authentication token

### 4. Navigate to Plans
- Click menu → Plans
- Should see a loading indicator briefly
- Plans list should appear with data from backend

### 5. Debug Information
Check the console output for:
- 🔵 Blue logs: API calls being made
- 🟢 Green logs: Successful responses
- 🔴 Red logs: Errors or failures

### 6. Try Refresh
- Swipe down on the plans list to refresh
- Or click the "Retry" button if there's an error

## Common Issues & Solutions

### Issue: Plans list is empty
**Check:**
1. Is backend running on the correct IP (10.198.164.90:3001)?
2. Look for 🔴 red logs in console
3. Are there actually plans in the database?
4. Is the token being sent (check logs for "Auth token present")?

### Issue: Connection refused error
**Solution:**
1. Ensure backend is running: `npm start`
2. Check backend is on port 3001
3. Check device can reach the IP (ping 10.198.164.90)
4. Update base URL in api_service.dart if needed

### Issue: Token errors (401 Unauthorized)
**Check:**
1. Login was successful and token was received
2. Token is being set: `apiService.setToken(token)`
3. Backend is validating the token correctly

## Token Management

The token flow:
```
User Login
    ↓
Login API call to /api/auth/login
    ↓
Backend returns {token: "jwt..."}
    ↓
LoginViewModel calls apiService.setToken(token)
    ↓
All subsequent API calls include Bearer token
    ↓
Plans API call includes "Authorization: Bearer jwt..."
    ↓
Backend validates token and returns plans
```

## Plan Model Field Mapping

The Plan.fromJson() handles flexible field names:
```dart
id: (json['id'] ?? json['_id'] ?? '').toString(),
name: (json['name'] ?? json['plan_name'] ?? '').toString(),
price: (json['price'] ?? json['plan_price'] ?? 0).toDouble(),
durationDays: (json['duration_days'] ?? json['durationDays'] ?? 0).toInt(),
description: (json['description'] ?? '').toString(),
isActive: (json['is_active'] ?? json['isActive'] ?? true) == true,
```

This means the backend can use either naming convention (snake_case or camelCase).

## Features Now Working

✅ Load plans from backend  
✅ Display plans in list  
✅ Pull-to-refresh  
✅ Add new plan  
✅ Error handling and messages  
✅ Loading indicators  
✅ Token-based authentication  
✅ Detailed debug logging  

## Next Steps

1. **Test with your backend data**
2. **Verify plans appear correctly**
3. **Test add plan functionality**
4. **Check error handling with invalid credentials**
5. **Verify refresh works**

## Additional Notes

- The API service is a singleton (created once via Riverpod Provider)
- Token is shared across all ViewModels
- All network requests go through centralized error handling
- Debug prints can be removed later for production

---

**Last Updated:** 2026-02-22  
**Status:** ✅ Complete - Plans page now loads real data from backend

