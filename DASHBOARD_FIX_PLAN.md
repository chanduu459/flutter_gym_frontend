# Dashboard Real Data Integration Fix

## Issues to Fix

1. **Expiring 7 Days Card** - Should show real data from API
2. **Expired Card** - Should show real expired subscription count
3. **Monthly Revenue** - Should include subscription amounts when customers are added

## What Needs to Change

### 1. Dashboard ViewModel
- Add method to fetch expired subscriptions
- Enhance `_initializeDashboard()` to calculate monthly revenue including subscription amounts
- Parse subscription prices and dates to calculate revenue

### 2. Dashboard Screen
- Show real expiring subscription count from API
- Show real expired subscription count from API
- Display subscription details in the "Expiring Soon" section

### 3. API Service
- Already has `getDashboardStats()` - should return expiredSubscriptions count
- Already has `getExpiringSubscriptions()` - need to ensure it returns full data

### 4. Backend Integration
- Dashboard stats endpoint should return:
  - `activeMembers` - count of active subscriptions
  - `expiringSubscriptions` - count expiring in 7 days
  - `expiredSubscriptions` - count of expired/inactive subscriptions
  - `monthlyRevenue` - total revenue from subscriptions (with prices)
  - `renewalRate` - percentage of renewals
  - `revenueTrend` - monthly breakdown with amounts
  - `membershipBreakdown` - object with active, expiring, expired counts

---

## Implementation Plan

1. **Update Dashboard ViewModel**
   - Enhance data fetching and parsing
   - Add method to calculate monthly revenue including subscription prices
   - Fetch expired subscriptions count

2. **Update Dashboard Screen**
   - Display actual stats from API
   - Show subscription list with details

3. **Documentation**
   - Create implementation guide
   - Create testing checklist

---

## Expected Data Flow

```
Backend API
    ↓
getExpiringSubscriptions(days: 7) → List of subscriptions ending in 7 days
getDashboardStats() → Statistics including:
    - activeMembers: int
    - expiringSubscriptions: int
    - expiredSubscriptions: int
    - monthlyRevenue: double (sum of all active subscriptions)
    - revenueTrend: [{month, amount}, ...]
    - membershipBreakdown: {active, expiring, expired}
    ↓
Dashboard ViewModel → Parse and format data
    ↓
Dashboard Screen → Display with real values
```
