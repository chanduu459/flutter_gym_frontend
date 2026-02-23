# Members Page - Camera Integration Guide

## Overview
Camera functionality has been successfully integrated into the "Add New Member" dialog. Members can now capture their face directly from the camera or upload an image from their device gallery.

## Features Added

### 1. **Real Camera Capture**
- Users can open the device camera to capture a face photo
- Image quality set to 85% for optimal balance between quality and file size
- Automatic image preview after capture

### 2. **Image Gallery Upload**
- Users can browse and select an image from their device gallery
- Supports all standard image formats
- Same quality optimization as camera capture

### 3. **Image Preview**
- Displays a thumbnail preview of the selected image
- Shows filename for confirmation
- Green success indicator with checkmark
- Only displays if file exists on device

### 4. **Form Integration**
- Face image is now properly passed to the backend API
- Image is sent as multipart form data with member details
- Optional field - members can be created without an image

## Files Modified

### 1. **lib/screens/members_screen.dart**
**Changes:**
- Added imports for `image_picker` package
- Added imports for `dart:io` for File handling
- Updated "Use Camera" button to capture real images
- Updated "Upload File" button to select from gallery
- Added image preview with checkmark indicator
- Modified Create Member button to pass File object

**Key Code:**
```dart
// Camera capture
final picker = ImagePicker();
final image = await picker.pickImage(
  source: ImageSource.camera,
  imageQuality: 85,
);
if (image != null) {
  
  setState(() {
    selectedFaceImage = image.path;
  });
}

// Gallery upload
final image = await picker.pickImage(
  source: ImageSource.gallery,
  imageQuality: 85,
);
```

### 2. **lib/viewmodels/members_viewmodel.dart**
**Changes:**
- Added `import 'dart:io'` for File type
- Updated `addMember()` method signature
- Changed `faceImage: String?` to `faceImageFile: File?`
- Passes File object to API service

**Method Signature:**
```dart
Future<void> addMember({
  required String fullName,
  required String email,
  required String phone,
  File? faceImageFile,  // Changed from String
  String? password,
}) async
```

## UI/UX Improvements

### Add Member Dialog Layout
```
┌─────────────────────────────┐
│ Add New Member              │
├─────────────────────────────┤
│                             │
│ Full Name: [_________]      │
│ Email: [_______________]    │
│ Phone: [_______________]    │
│                             │
│ Face Image (optional)       │
│ [Upload File] [Use Camera]  │
│                             │
│ ✓ Image selected: photo.jpg │
│ ┌─────────────────────────┐ │
│ │                         │ │
│ │  [Image Preview 150x100]│ │
│ │                         │ │
│ └─────────────────────────┘ │
│                             │
│ Password (optional)         │
│ [_________]                 │
│ Leave blank for default     │
│                             │
│ [Cancel] [Create Member]    │
└─────────────────────────────┘
```

## Image Handling

### Camera Capture Flow
1. User taps "Use Camera" button
2. Device camera opens
3. User captures face image
4. Image compressed to quality 85%
5. File path stored in `selectedFaceImage`
6. Preview displayed in form

### Gallery Upload Flow
1. User taps "Upload File" button
2. Device gallery opens
3. User selects image
4. Image compressed to quality 85%
5. File path stored in `selectedFaceImage`
6. Preview displayed in form

### Form Submission Flow
1. User fills in all required fields
2. Image file converted to File object
3. Form submitted with File object
4. API service sends as multipart/form-data
5. Backend processes image and saves member

## Backend API Integration

The image is sent to the backend as multipart form data:

**Endpoint:** `POST /api/members`

**Form Data:**
```
- fullName: string
- email: string
- phone: string
- faceImage: File (optional)
- password: string (optional)
```

**API Service Method:**
```dart
Future<Map<String, dynamic>> createMember({
  required String fullName,
  required String email,
  required String phone,
  String? password,
  File? faceImage,
}) async {
  // Multipart upload handled by _multipart() method
  // File sent with field name 'faceImage'
}
```

## Error Handling

### Camera Errors
- Try-catch block handles camera access errors
- SnackBar displays error message to user
- Users can retry or use gallery upload instead

### File Errors
- Checks if file exists before preview
- Validates file path integrity
- Shows error message if file cannot be read

## Dependencies

### Required Packages
- `image_picker: ^1.0.0+` - For camera and gallery access
- `flutter: ^3.0.0` - Flutter framework

### Permissions Required

**Android (android/app/src/main/AndroidManifest.xml)**
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

**iOS (ios/Runner/Info.plist)**
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to capture member photos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to select member photos</string>
```

## Testing Guide

### Test Camera Capture
1. Open Members screen
2. Click "Add Member"
3. Fill in Name, Email, Phone
4. Click "Use Camera"
5. Capture a face photo
6. Verify preview shows image
7. Click "Create Member"
8. Verify member created with face image

### Test Gallery Upload
1. Open Members screen
2. Click "Add Member"
3. Fill in Name, Email, Phone
4. Click "Upload File"
5. Select image from gallery
6. Verify preview shows image
7. Click "Create Member"
8. Verify member created with face image

### Test Without Image
1. Open Members screen
2. Click "Add Member"
3. Fill in Name, Email, Phone
4. Skip image selection
5. Click "Create Member"
6. Verify member created without face image

## Status

✅ Camera capture implemented
✅ Gallery upload implemented
✅ Image preview display
✅ File handling and validation
✅ Backend API integration
✅ Error handling
✅ User feedback (SnackBars)

## Next Steps (Optional)

1. **Image Cropping** - Add image cropping tool before upload
2. **Face Detection** - Validate that uploaded image contains a face
3. **Image Compression** - Further optimize image size
4. **Multiple Images** - Allow uploading multiple photos per member
5. **Image Editing** - Add filters or adjustments before upload

## Notes

- Images are compressed to quality 85% for optimal balance
- File picker uses native device UI for better UX
- Image preview only shows if file is valid and readable
- All errors are handled gracefully with user feedback
- Compatible with both Android and iOS platforms

