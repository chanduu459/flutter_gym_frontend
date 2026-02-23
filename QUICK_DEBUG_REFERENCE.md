# Quick Debugging Reference

## Issue: Members Not Saved to Database

### Step 1: Check API Service
```dart
// In api_service.dart, add temporary debug logging
Future<Map<String, dynamic>> createMember({...}) async {
  print('=== CREATE MEMBER DEBUG ===');
  print('Full Name: $fullName');
  print('Email: $email');
  print('Phone: $phone');
  print('Face Image provided: ${faceImage != null}');
  if (faceImage != null) {
    print('File exists: ${faceImage.existsSync()}');
    print('File path: ${faceImage.path}');
    print('File size: ${faceImage.lengthSync()} bytes');
  }
  
  try {
    // ... rest of method ...
  } catch (e) {
    print('ERROR: $e');
    rethrow;
  }
}
```

### Step 2: Check Backend Logs
```bash
# Check if POST request reaches backend
# Look for: POST /api/members

# Check if file upload succeeds
# Look for: multipart form data

# Check if database save succeeds
# Look for: INSERT INTO members
```

### Step 3: Check Network Inspector
1. Open Browser DevTools → Network tab (if web)
2. Or use Flutter DevTools → Network tab
3. Look for `POST /api/members` request
4. Check:
   - Request headers (should have Bearer token)
   - Request body (should contain form data or JSON)
   - Response status (should be 201 or 200)
   - Response body (should contain created member)

### Step 4: Check Database
```sql
-- Check if member exists
SELECT * FROM members WHERE email = 'test@example.com';

-- Check if record was created
SELECT COUNT(*) FROM members;

-- Check for any errors in creation
SELECT * FROM members WHERE created_at > NOW() - INTERVAL '1 minute';
```

---

## Issue: White Box Instead of Image Display

### Check 1: Verify File Exists
```dart
void _debugImageDisplay(String? selectedFaceImage) {
  if (selectedFaceImage == null) {
    print('ERROR: selectedFaceImage is null');
    return;
  }
  
  final file = File(selectedFaceImage);
  print('File path: ${file.path}');
  print('File exists: ${file.existsSync()}');
  
  if (!file.existsSync()) {
    print('ERROR: File does not exist at ${file.path}');
    return;
  }
  
  print('File size: ${file.lengthSync()} bytes');
}
```

### Check 2: Verify Image Widget Code
```dart
// Correct implementation
if (selectedFaceImage != null && File(selectedFaceImage!).existsSync()) {
  Image.file(
    File(selectedFaceImage!),
    height: 180,
    width: double.infinity,
    fit: BoxFit.cover,
  )
} else {
  Text('No image selected or file not found')
}
```

### Check 3: Check File Permissions
- Android: Check `AndroidManifest.xml` permissions
- iOS: Check `Info.plist` permissions
- Check file picker camera permissions granted

---

## Issue: Members List Empty

### Check 1: Verify API Endpoint Works
```bash
# Test the endpoint directly
curl -X GET http://10.198.164.90:3001/api/members \
  -H "Authorization: Bearer YOUR_TOKEN"

# Should return:
# {
#   "data": [
#     { "id": "...", "full_name": "...", ... },
#     ...
#   ]
# }
```

### Check 2: Check ViewModels
```dart
// In members_viewmodel.dart, add debug logging
Future<void> _initializeMembers() async {
  try {
    print('=== LOADING MEMBERS ===');
    state = state.copyWith(isLoading: true, errorMessage: null);

    final data = await _api.getMembers();
    print('Response data: $data');
    print('Data type: ${data.runtimeType}');

    List<dynamic> membersList = data is List ? data : [];
    print('Members list length: ${membersList.length}');

    final members = membersList
        .map((json) {
          print('Parsing member: $json');
          if (json is Map<String, dynamic>) {
            return Member.fromJson(json);
          } else if (json is Map) {
            return Member.fromJson(json.cast<String, dynamic>());
          }
          return null;
        })
        .whereType<Member>()
        .toList();

    print('Successfully parsed ${members.length} members');

    state = state.copyWith(
      isLoading: false,
      members: members,
      errorMessage: null,
    );
  } catch (e) {
    print('ERROR loading members: $e');
    state = state.copyWith(
      isLoading: false,
      errorMessage: 'Failed to load members: $e',
    );
  }
}
```

### Check 3: Check Screen Init
```dart
@override
void initState() {
  super.initState();
  print('=== MEMBERS SCREEN INIT ===');
  Future.microtask(() {
    print('Calling refresh...');
    ref.read(membersViewModelProvider.notifier).refresh();
  });
}
```

---

## Issue: Face Recognition Not Resetting After 10 Seconds

### Check 1: Verify Timer Execution
```dart
void _startAutoRefreshTimer() {
  print('=== STARTING AUTO-REFRESH TIMER ===');
  _autoRefreshTimer?.cancel();

  _autoRefreshTimer = Timer(const Duration(seconds: 10), () {
    print('=== AUTO-REFRESH TRIGGERED ===');
    final faceState = ref.read(faceRecognitionViewModelProvider);
    print('Is recognized: ${faceState.isRecognized}');
    print('Is mounted: $mounted');

    if (faceState.isRecognized && mounted) {
      print('Calling resetCamera...');
      final viewModel = ref.read(faceRecognitionViewModelProvider.notifier);
      viewModel.resetCamera();
      print('Reset complete');
    } else {
      print('Auto-refresh skipped - not recognized or unmounted');
    }
  });
}

@override
void dispose() {
  print('=== DISPOSING FACE RECOGNITION SCREEN ===');
  print('Timer active: ${_autoRefreshTimer != null}');
  _autoRefreshTimer?.cancel();
  final viewModel = ref.read(faceRecognitionViewModelProvider.notifier);
  viewModel.closeCamera();
  super.dispose();
}
```

### Check 2: Check State Updates
```dart
@override
Widget build(BuildContext context) {
  final faceState = ref.watch(faceRecognitionViewModelProvider);
  final faceViewModel = ref.read(faceRecognitionViewModelProvider.notifier);

  print('=== BUILD FACE RECOGNITION SCREEN ===');
  print('Is recognized: ${faceState.isRecognized}');
  print('Is camera open: ${faceState.isCameraOpen}');
  print('Timer active: ${_autoRefreshTimer != null}');

  // Start auto-refresh timer when face is recognized
  if (faceState.isRecognized && _autoRefreshTimer == null) {
    print('Starting auto-refresh timer...');
    _startAutoRefreshTimer();
  }

  // ... rest of build ...
}
```

---

## Common Error Messages & Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| `Failed to add file to request` | File doesn't exist or not readable | Check file path and permissions |
| `Failed to send request` | Network error | Check network connectivity |
| `Invalid response from server` | Server returned non-JSON | Check backend API response format |
| `API request failed (Status: 400)` | Invalid request data | Check required fields (fullName, email, phone) |
| `API request failed (Status: 401)` | Not authenticated | Check token validity, re-login if needed |
| `API request failed (Status: 500)` | Server error | Check backend logs for details |
| `File does not exist` | Image path invalid | Check if file was actually created |
| `No members found` | Empty list returned | Verify members were created in DB |

---

## Flutter DevTools Debugging

### Open DevTools
```bash
flutter pub global activate devtools
flutter pub global run devtools

# Or if run within IDE
```

### Check Riverpod State
1. Open DevTools
2. Go to "Riverpod" tab (if using Riverpod DevTools)
3. Watch `membersViewModelProvider` state changes
4. Watch `faceRecognitionViewModelProvider` state changes

### Monitor Network Requests
1. Open DevTools
2. Go to "Network" tab
3. Look for `/api/members` POST request
4. Check request/response details

---

## Logcat for Android
```bash
adb logcat | grep "flutter"

# Or specific app
adb logcat | grep "com.example.gymsas_myapp"
```

---

## iOS Console
1. Open Xcode
2. Run app
3. View console output in Xcode Debug Area

---

## Android Studio / IntelliJ
1. Open IDE
2. View → Tool Windows → Logcat
3. Filter by app name or "flutter"

---

## Test with curl

### Create Member (No Image)
```bash
curl -X POST http://10.198.164.90:3001/api/members \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "fullName": "Test User",
    "email": "test@example.com",
    "phone": "+1234567890",
    "password": "welcome123"
  }'
```

### Get Members
```bash
curl -X GET http://10.198.164.90:3001/api/members \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Enable Verbose Logging in Flutter
```bash
# Run with debug logging
flutter run -v

# Or in code
debugPrint('message'); // This shows in console
print('message');       // This may not show in release
```

---

## Quick Checklist When Things Break

- [ ] Check console for error messages
- [ ] Verify API endpoint is correct
- [ ] Check network connectivity
- [ ] Verify token/authentication
- [ ] Check required fields are present
- [ ] Check file exists and is readable
- [ ] Check database connection on backend
- [ ] Check backend logs
- [ ] Try with curl/Postman first
- [ ] Clear app cache and reinstall
- [ ] Check widget lifecycle (initState, dispose)
- [ ] Verify state management updates

---

**Pro Tip**: Always add `print()` statements around critical operations when debugging!

