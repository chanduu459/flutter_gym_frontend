# 🔧 Fix: FormatException Error - API Response Parsing

## Problem
Error shown: **"Recognition failed: FormatException: Unexpected character (at character 1) <!DOCTYPE html>"**

## Root Cause
The backend API is returning an HTML error page instead of JSON. This happens when:
1. API endpoint not found (404)
2. Server error (500)
3. Wrong API URL/path
4. Server crashed

## Solution Applied

### ✅ Enhanced Error Handling in API Service
Added checks to detect HTML responses and provide better error messages:

```dart
// Check if response is HTML (error page) instead of JSON
if (response.body.trim().startsWith('<')) {
  throw ApiException(
    'Server error: ${response.statusCode}. Please check your backend API.'
  );
}

// Safe JSON decoding with error handling
dynamic decoded;
try {
  decoded = jsonDecode(response.body);
} catch (e) {
  throw ApiException('Invalid response from server: ${e.toString()}');
}
```

## What Changed
**Before:** Direct `jsonDecode()` → crashes on HTML
**After:** Check for HTML first → provide useful error message

## How to Debug

### Step 1: Check API Endpoint
Verify the endpoint exists:
```bash
curl -X POST http://10.198.164.90:3001/api/auth/identify-face \
  -H "Content-Type: application/json" \
  -d '{"imageBase64": "test"}'
```

Should return JSON, not HTML error page.

### Step 2: Check Backend Logs
Look for errors in your backend logs:
- Is the `/api/auth/identify-face` endpoint defined?
- Is the AWS Rekognition service initialized?
- Is the database connection working?

### Step 3: Verify API URL
Check in `lib/services/api_service.dart`:
```dart
_baseUrl = baseUrl ??
    const String.fromEnvironment(
      'API_URL',
      defaultValue: 'http://10.198.164.90:3001',
    );
```

Ensure `http://10.198.164.90:3001` is correct.

### Step 4: Check Backend Code
Verify backend endpoint:
```javascript
// Backend should respond with JSON
app.post('/api/auth/identify-face', async (req, res) => {
  try {
    const { imageBase64 } = req.body;
    // AWS Rekognition processing...
    return res.json({
      recognized: true/false,
      member: {...},
      confidence: 0.95
    });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});
```

## Testing

### Deploy Updated Code
```bash
flutter clean
flutter pub get
flutter run -d <device-id>
```

### Test Again
1. Open app
2. Tap "Face Recognition"
3. Tap "📷 Open Camera"
4. Tap "Start Recognition"
5. Check error message

### Expected Results

**If API working:**
- ✅ Success message with member name
- ✅ Confidence score displayed

**If API not found:**
- ❌ "Server error: 404. Please check your backend API."

**If AWS Rekognition error:**
- ❌ Error message from backend
- ✅ Now readable (not FormatException)

## Files Modified
- ✅ `lib/services/api_service.dart` - Added HTML detection and safe JSON parsing

## Status
✅ Error handling improved
✅ Better error messages
✅ Ready to test with working backend

## Next Steps
1. Check your backend API is running
2. Verify endpoint `/api/auth/identify-face` exists
3. Test with curl to ensure JSON response
4. Deploy updated app
5. Test face recognition again

The app will now show clear error messages instead of FormatException!

