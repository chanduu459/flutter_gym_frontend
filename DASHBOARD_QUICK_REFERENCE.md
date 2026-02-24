# Dashboard Real Data Integration - Quick Reference

## What Changed?

### ✅ Frontend Code (Complete)

**File 1: `lib/viewmodels/dashboard_viewmodel.dart`**
- Added `planName`, `planPrice`, `daysRemaining` to ExpiringSubscription
- Enhanced `_initializeDashboard()` to parse subscription data
- Updated `runExpiryCheck()` to call backend

**File 2: `lib/screens/dashboard_screen.dart`**
- Redesigned `_SubscriptionTile` to show:
  - Plan name and price
  - Days remaining with color badge
  - Smart expiry text ("Expires today", "Expires in 5 days")
  - Color coding (Red/Orange based on urgency)

### 🔄 Backend Required

Your backend needs to return data in this format:

```javascript
// GET /api/dashboard/stats
{
  "data": {
    "activeMembers": 25,
    "expiringSubscriptions": 3,
    "expiredSubscriptions": 2,
    "monthlyRevenue": 4500,
    "renewalRate": 85,
    "revenueTrend": [
      {"month": "Jan", "amount": 3000},
      {"month": "Feb", "amount": 3500},
      {"month": "Mar", "amount": 4500}
    ],
    "membershipBreakdown": {
      "active": 25,
      "expiring": 3,
      "expired": 2
    }
  }
}

// GET /api/subscriptions/expiring?days=7
{
  "data": [
    {
      "memberId": "123",
      "memberName": "John Doe",
      "email": "john@example.com",
      "phone": "+1234567890",
      "planName": "Premium",
      "planPrice": 99.99,
      "expiryDate": "2026-03-01T00:00:00Z",
      "status": "7_days"
    }
  ]
}

// POST /api/cron/check-expiring
{
  "data": {
    "checked": 30,
    "expired": 2,
    "expiring_soon": 3
  }
}
```

---

## Testing Quick Checklist

```bash
# Test backend endpoints
curl -X GET http://localhost:3001/api/dashboard/stats -H "Authorization: Bearer TOKEN"
curl -X GET "http://localhost:3001/api/subscriptions/expiring?days=7" -H "Authorization: Bearer TOKEN"
curl -X POST http://localhost:3001/api/cron/check-expiring -H "Authorization: Bearer TOKEN"
```

## Dashboard Display

### Before ❌
```
Active Members:        0
Expiring (7 days):     0
Expired:               0
Monthly Revenue:       $0

Expiring Soon List:
  (empty)
```

### After ✅
```
Active Members:        25
Expiring (7 days):     3
Expired:               2
Monthly Revenue:       $4,500.00

Expiring Soon List:
  John Doe              [Expires in 5 days] 🟡
  jane@example.com
  +1234567890
  Plan: Premium         $99.99
  
  Jane Smith            [Expires today] 🔴
  jane@example.com
  +0987654321
  Plan: Basic           $49.99
```

---

## Key Implementation Details

### 1. Monthly Revenue Calculation
```dart
// Backend sends monthlyRevenue as total
// Frontend displays as formatted string
monthlyRevenue: '\$${calculatedRevenue.toStringAsFixed(2)}'

// Example:
4500.00 → "$4500.00"
```

### 2. Days Remaining Calculation
```dart
// Days remaining = expiryDate - today
final daysRemaining = expiryDate.difference(DateTime.now()).inDays;

// Color coding:
if (daysRemaining == 0) color = Colors.red;        // "Expires today"
if (daysRemaining <= 3) color = Colors.deepOrange; // "Expires in X days"
if (daysRemaining <= 7) color = Colors.orange;     // "Expires in X days"
```

### 3. Status Determination
```dart
// Status auto-determined from daysRemaining
status = daysRemaining <= 3 ? '3_days' 
       : daysRemaining <= 7 ? '7_days'
       : 'other'
```

---

## Files to Review

1. **DASHBOARD_BACKEND_REQUIREMENTS.md**
   - Complete API specifications
   - Node.js implementation examples
   - Response format details

2. **DASHBOARD_TESTING_IMPLEMENTATION.md**
   - Testing procedures
   - Troubleshooting guide
   - Code review checklist

3. **DASHBOARD_REAL_DATA_SUMMARY.md**
   - Overview of all changes
   - Data flow diagram
   - Completion status

---

## Troubleshooting

| Problem | Check |
|---------|-------|
| Dashboard shows $0 | Backend returning monthlyRevenue? |
| No expiring subscriptions | Any subscriptions within 7 days in DB? |
| Plan price not showing | API includes planPrice field? |
| Colors not showing | expiryDate in correct format? |
| Expiry check fails | /api/cron/check-expiring endpoint exists? |

---

## Next Steps

1. ✅ **Frontend Code**: Updated and ready
2. 🔄 **Backend Code**: Implement endpoints (see DASHBOARD_BACKEND_REQUIREMENTS.md)
3. 🔄 **Testing**: Run tests (see DASHBOARD_TESTING_IMPLEMENTATION.md)
4. 🔄 **Deployment**: Deploy both frontend and backend

---

## Important Notes

- **All prices** should include subscription amounts
- **All dates** should be ISO format (YYYY-MM-DDTHH:mm:ssZ)
- **All counts** should match active subscriptions
- **Monthly revenue** = sum of all active subscription prices
- **Status colors** auto-determined from days remaining

---

**Status**: ✅ Frontend Complete - Awaiting Backend Integration

Review **DASHBOARD_BACKEND_REQUIREMENTS.md** to implement backend endpoints.
