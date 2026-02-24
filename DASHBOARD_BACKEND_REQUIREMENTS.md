# Dashboard Real Data Integration - Backend Requirements

## Overview
This guide explains the data structure that the backend API should return for the dashboard to display real data correctly.

---

## API Endpoints Required

### 1. GET `/api/dashboard/stats`

**Purpose**: Return overall dashboard statistics

**Response Format**:
```json
{
  "data": {
    "activeMembers": 25,
    "expiringSubscriptions": 3,
    "expiredSubscriptions": 2,
    "monthlyRevenue": 4500.00,
    "renewalRate": 85,
    "revenueTrend": [
      {
        "month": "Jan",
        "amount": 3000
      },
      {
        "month": "Feb",
        "amount": 3500
      },
      {
        "month": "Mar",
        "amount": 4500
      }
    ],
    "membershipBreakdown": {
      "active": 25,
      "expiring": 3,
      "expired": 2
    }
  },
  "message": "Dashboard stats retrieved successfully"
}
```

**Field Descriptions**:
- `activeMembers` (int): Count of currently active members
- `expiringSubscriptions` (int): Count of subscriptions expiring in next 7 days
- `expiredSubscriptions` (int): Count of expired/inactive subscriptions
- `monthlyRevenue` (number): Total revenue for current month (sum of active subscriptions)
- `renewalRate` (int): Percentage of subscriptions renewed last month
- `revenueTrend` (array): Monthly revenue data for chart display
  - `month` (string): Month abbreviation (Jan, Feb, Mar, etc.)
  - `amount` (number): Revenue amount for that month
- `membershipBreakdown` (object): Breakdown of membership statuses
  - `active` (int): Active memberships
  - `expiring` (int): Expiring soon (7 days)
  - `expired` (int): Already expired

---

### 2. GET `/api/subscriptions/expiring?days=7`

**Purpose**: Return list of subscriptions expiring within specified days

**Response Format**:
```json
{
  "data": [
    {
      "memberId": "member123",
      "memberName": "John Doe",
      "email": "john@example.com",
      "phone": "+1234567890",
      "planName": "Premium",
      "planPrice": 99.99,
      "expiryDate": "2026-03-01T00:00:00Z",
      "status": "7_days"
    },
    {
      "memberId": "member456",
      "memberName": "Jane Smith",
      "email": "jane@example.com",
      "phone": "+0987654321",
      "planName": "Basic",
      "planPrice": 49.99,
      "expiryDate": "2026-02-25T00:00:00Z",
      "status": "3_days"
    }
  ],
  "message": "Expiring subscriptions retrieved"
}
```

**Field Descriptions**:
- `memberId` (string): Unique member identifier
- `memberName` (string): Full name of the member
- `email` (string): Member email address
- `phone` (string): Member phone number
- `planName` (string): Name of the subscription plan
- `planPrice` (number): Price of the plan (important for revenue calculation)
- `expiryDate` (string): ISO date when subscription expires
- `status` (string): Status indicator
  - "7_days" = expires within 7 days
  - "3_days" = expires within 3 days
  - "today" = expires today

---

### 3. POST `/api/cron/check-expiring`

**Purpose**: Run expiry check and update subscription statuses

**Request**: No body required

**Response Format**:
```json
{
  "data": {
    "checked": 30,
    "expired": 2,
    "expiring_soon": 3,
    "message": "Expiry check completed"
  },
  "message": "Expiry check ran successfully"
}
```

---

## Implementation Examples

### Node.js/Express Backend

#### Dashboard Stats Endpoint
```javascript
router.get('/dashboard/stats', authenticateToken, async (req, res) => {
  try {
    const gymId = req.user.gymId;

    // Get active members count
    const activeMembers = await Member.countDocuments({
      gym_id: gymId,
      is_active: true
    });

    // Get subscriptions data
    const now = new Date();
    const sevenDaysFromNow = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

    // Expiring in 7 days
    const expiringSubscriptions = await Subscription.countDocuments({
      gym_id: gymId,
      expiry_date: {
        $gt: now,
        $lte: sevenDaysFromNow
      },
      status: 'active'
    });

    // Already expired
    const expiredSubscriptions = await Subscription.countDocuments({
      gym_id: gymId,
      expiry_date: { $lt: now },
      status: 'active'
    });

    // Calculate monthly revenue
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const monthEnd = new Date(now.getFullYear(), now.getMonth() + 1, 0);

    const monthlyRevenue = await Subscription.aggregate([
      {
        $match: {
          gym_id: gymId,
          status: 'active',
          created_at: { $gte: monthStart, $lte: monthEnd }
        }
      },
      {
        $lookup: {
          from: 'plans',
          localField: 'plan_id',
          foreignField: '_id',
          as: 'plan'
        }
      },
      {
        $unwind: '$plan'
      },
      {
        $group: {
          _id: null,
          total: { $sum: '$plan.price' }
        }
      }
    ]);

    // Revenue trend (last 3-6 months)
    const revenueTrend = await Subscription.aggregate([
      {
        $match: {
          gym_id: gymId,
          status: 'active'
        }
      },
      {
        $lookup: {
          from: 'plans',
          localField: 'plan_id',
          foreignField: '_id',
          as: 'plan'
        }
      },
      {
        $unwind: '$plan'
      },
      {
        $group: {
          _id: {
            $dateToString: { format: '%Y-%m', date: '$created_at' }
          },
          amount: { $sum: '$plan.price' }
        }
      },
      { $sort: { _id: 1 } },
      {
        $project: {
          _id: 0,
          month: {
            $arrayElemAt: [
              ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
              { $subtract: [{ $toInt: { $substr: ['$_id', 5, 2] } }, 1] }
            ]
          },
          amount: 1
        }
      }
    ]);

    // Renewal rate (subscriptions renewed this month)
    const renewalRate = await Subscription.aggregate([
      {
        $match: {
          gym_id: gymId,
          status: 'active',
          created_at: { $gte: monthStart, $lte: monthEnd }
        }
      },
      { $count: 'renewed' }
    ]);

    const stats = {
      activeMembers,
      expiringSubscriptions,
      expiredSubscriptions,
      monthlyRevenue: monthlyRevenue[0]?.total || 0,
      renewalRate: renewalRate[0]?.renewed || 0,
      revenueTrend: revenueTrend || [],
      membershipBreakdown: {
        active: activeMembers,
        expiring: expiringSubscriptions,
        expired: expiredSubscriptions
      }
    };

    return res.json({
      data: stats,
      message: 'Dashboard stats retrieved successfully'
    });
  } catch (error) {
    console.error('Dashboard stats error:', error);
    return res.status(500).json({ error: error.message });
  }
});
```

#### Expiring Subscriptions Endpoint
```javascript
router.get('/subscriptions/expiring', authenticateToken, async (req, res) => {
  try {
    const gymId = req.user.gymId;
    const days = parseInt(req.query.days) || 7;

    const now = new Date();
    const expiryBefore = new Date(now.getTime() + days * 24 * 60 * 60 * 1000);

    const expiringSubscriptions = await Subscription.aggregate([
      {
        $match: {
          gym_id: gymId,
          expiry_date: {
            $gt: now,
            $lte: expiryBefore
          },
          status: 'active'
        }
      },
      {
        $lookup: {
          from: 'members',
          localField: 'member_id',
          foreignField: '_id',
          as: 'member'
        }
      },
      { $unwind: '$member' },
      {
        $lookup: {
          from: 'plans',
          localField: 'plan_id',
          foreignField: '_id',
          as: 'plan'
        }
      },
      { $unwind: '$plan' },
      {
        $project: {
          memberId: '$member._id',
          memberName: '$member.full_name',
          email: '$member.email',
          phone: '$member.phone',
          planName: '$plan.name',
          planPrice: '$plan.price',
          expiryDate: '$expiry_date',
          status: {
            $cond: [
              { $lte: ['$expiry_date', new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000)] },
              '3_days',
              '7_days'
            ]
          }
        }
      },
      { $sort: { expiryDate: 1 } }
    ]);

    return res.json({
      data: expiringSubscriptions,
      message: 'Expiring subscriptions retrieved'
    });
  } catch (error) {
    console.error('Expiring subscriptions error:', error);
    return res.status(500).json({ error: error.message });
  }
});
```

#### Expiry Check Endpoint
```javascript
router.post('/cron/check-expiring', authenticateToken, async (req, res) => {
  try {
    const gymId = req.user.gymId;
    const now = new Date();

    // Find subscriptions that have expired
    const expiredCount = await Subscription.updateMany(
      {
        gym_id: gymId,
        expiry_date: { $lte: now },
        status: 'active'
      },
      {
        status: 'expired',
        updated_at: now
      }
    );

    // Find subscriptions expiring soon (notify)
    const expiringCount = await Subscription.countDocuments({
      gym_id: gymId,
      expiry_date: {
        $gt: now,
        $lte: new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000)
      },
      status: 'active'
    });

    return res.json({
      data: {
        checked: expiredCount.modifiedCount,
        expired: expiredCount.modifiedCount,
        expiring_soon: expiringCount
      },
      message: 'Expiry check completed'
    });
  } catch (error) {
    console.error('Expiry check error:', error);
    return res.status(500).json({ error: error.message });
  }
});
```

---

## Dashboard Data Flow

```
1. Dashboard Screen Loads
   ↓
2. Dashboard ViewModel calls:
   - getDashboardStats()
   - getExpiringSubscriptions(days: 7)
   ↓
3. Backend returns:
   - Stats with counts and revenue
   - List of expiring subscriptions with details
   ↓
4. ViewModel parses data:
   - Calculates days remaining
   - Formats revenue with currency
   - Determines status colors
   ↓
5. Dashboard Screen displays:
   - Active Members card: Shows count from activeMembers
   - Expiring (7 days) card: Shows count from expiringSubscriptions
   - Expired card: Shows count from expiredSubscriptions
   - Monthly Revenue card: Shows formatted monthlyRevenue
   - Revenue Trend chart: Shows data from revenueTrend
   - Membership Pie chart: Shows breakdown
   - Expiring Soon list: Shows subscription details with:
     - Member name
     - Days remaining (auto-calculated)
     - Plan name and price
     - Email and phone
     - Expiry date
```

---

## Testing the Backend

### Test Dashboard Stats
```bash
curl -X GET http://localhost:3001/api/dashboard/stats \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Test Expiring Subscriptions
```bash
curl -X GET "http://localhost:3001/api/subscriptions/expiring?days=7" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Test Expiry Check
```bash
curl -X POST http://localhost:3001/api/cron/check-expiring \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Important Notes

1. **Monthly Revenue**: Should include subscription prices of all active members, not just new ones
2. **Expiry Dates**: Should be ISO format (YYYY-MM-DDTHH:mm:ssZ)
3. **Status Field**: Used to determine color coding in UI
4. **Days Calculation**: Frontend calculates remaining days using expiryDate - today
5. **Plan Price**: Essential for revenue calculations and member details
6. **Active Members**: Count should match active subscriptions

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Dashboard shows $0 revenue | Check if monthlyRevenue is being calculated from subscriptions |
| No expiring subscriptions shown | Verify expiry_date is correctly stored in database |
| Wrong member count | Ensure member.is_active flag is set correctly |
| Revenue trend doesn't show data | Verify revenueTrend array is populated with monthly data |
| Status not showing "3_days" | Check if dashboard is within 3 days of expiry |

---

**Remember**: All monetary values should be in the smallest unit (cents) or clearly specified as dollars with decimals.
