import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// Dashboard Models
class DashboardStats {
  final int activeMembers;
  final int expiringSubscriptions;
  final int expiredSubscriptions;
  final String monthlyRevenue;
  final String renewalRate;
  final List<RevenueData> revenueTrend;
  final MembershipBreakdown membershipBreakdown;

  DashboardStats({
    required this.activeMembers,
    required this.expiringSubscriptions,
    required this.expiredSubscriptions,
    required this.monthlyRevenue,
    required this.renewalRate,
    required this.revenueTrend,
    required this.membershipBreakdown,
  });

  DashboardStats copyWith({
    int? activeMembers,
    int? expiringSubscriptions,
    int? expiredSubscriptions,
    String? monthlyRevenue,
    String? renewalRate,
    List<RevenueData>? revenueTrend,
    MembershipBreakdown? membershipBreakdown,
  }) {
    return DashboardStats(
      activeMembers: activeMembers ?? this.activeMembers,
      expiringSubscriptions: expiringSubscriptions ?? this.expiringSubscriptions,
      expiredSubscriptions: expiredSubscriptions ?? this.expiredSubscriptions,
      monthlyRevenue: monthlyRevenue ?? this.monthlyRevenue,
      renewalRate: renewalRate ?? this.renewalRate,
      revenueTrend: revenueTrend ?? this.revenueTrend,
      membershipBreakdown: membershipBreakdown ?? this.membershipBreakdown,
    );
  }
}

class RevenueData {
  final String month;
  final double amount;

  RevenueData({required this.month, required this.amount});
}

class MembershipBreakdown {
  final int active;
  final int expiring;
  final int expired;

  MembershipBreakdown({
    required this.active,
    required this.expiring,
    required this.expired,
  });
}

class ExpiringSubscription {
  final String memberId;
  final String memberName;
  final String email;
  final String phone;
  final DateTime expiryDate;
  final String status; // "7_days", "3_days", "today"

  ExpiringSubscription({
    required this.memberId,
    required this.memberName,
    required this.email,
    required this.phone,
    required this.expiryDate,
    required this.status,
  });
}

class DashboardState {
  final DashboardStats? stats;
  final List<ExpiringSubscription>? expiringSubscriptions;
  final bool isLoading;
  final String? errorMessage;
  final bool hasExpired;

  DashboardState({
    this.stats,
    this.expiringSubscriptions,
    this.isLoading = false,
    this.errorMessage,
    this.hasExpired = false,
  });

  DashboardState copyWith({
    DashboardStats? stats,
    List<ExpiringSubscription>? expiringSubscriptions,
    bool? isLoading,
    String? errorMessage,
    bool? hasExpired,
  }) {
    return DashboardState(
      stats: stats ?? this.stats,
      expiringSubscriptions: expiringSubscriptions ?? this.expiringSubscriptions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      hasExpired: hasExpired ?? this.hasExpired,
    );
  }
}

class DashboardViewModel extends StateNotifier<DashboardState> {
  DashboardViewModel(this._api) : super(DashboardState(isLoading: true)) {
    _initializeDashboard();
  }

  final ApiService _api;

  Future<void> _initializeDashboard() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final statsData = await _api.getDashboardStats();
      final expiringData = await _api.getExpiringSubscriptions(days: 7);
      final allSubscriptions = await _api.getAllSubscriptions();

      // Debug logging
      print('📊 Dashboard Stats Response: $statsData');
      print('📅 Expiring Data Response: $expiringData');
      print('📅 Expiring Data Type: ${expiringData.runtimeType}');
      print('📅 Expiring Data Length: ${expiringData.length}');
      print('📋 All Subscriptions Count: ${allSubscriptions.length}');

      // Extract data from response - statsData is Map, expiringData is List
      Map<String, dynamic> statsDataMap = statsData;
      if (statsData.containsKey('data') && statsData['data'] is Map) {
        statsDataMap = statsData['data'] as Map<String, dynamic>;
      }

      List<dynamic> expiringList = expiringData;

      // Calculate expired subscriptions count
      int expiredCount = 0;
      try {
        final now = DateTime.now();
        expiredCount = allSubscriptions
            .where((item) {
              final data = item as Map<String, dynamic>;
              final expiryDate = DateTime.tryParse(
                (data['expiry_date'] ?? data['expiryDate'] ?? '').toString(),
              );
              return expiryDate != null && expiryDate.isBefore(now);
            })
            .length;
        print('🔴 Expired Subscriptions Count: $expiredCount');
      } catch (e) {
        print('❌ Error calculating expired subscriptions: $e');
      }

      print('📅 Expiring List Final Length: ${expiringList.length}');
      print('📅 Corrected Expiring Count (after -1): ${expiringList.length > 0 ? expiringList.length - 1 : 0}');

      final stats = DashboardStats(
        activeMembers: _extractInt(statsDataMap, [
          'activeMembers', 'active_members',
          'activeSubscriptions', 'active_subscriptions'
        ]),
        expiringSubscriptions: expiringList.length > 0 ? expiringList.length - 1 : 0,
        expiredSubscriptions: expiredCount > 0 ? expiredCount : 0,
        monthlyRevenue: '\$${_extractValue(statsDataMap, ['monthlyRevenue', 'monthly_revenue']) ?? '0'}',
        renewalRate: '${_extractValue(statsDataMap, ['renewalRate', 'renewal_rate']) ?? '0'}%',
        revenueTrend: _extractRevenueTrend(statsDataMap),
        membershipBreakdown: MembershipBreakdown(
          active: _extractInt(statsDataMap, [
            'membershipBreakdown.active', 'membership_breakdown.active'
          ]),
          expiring: expiringList.length > 0 ? expiringList.length - 1 : 0,
          expired: expiredCount > 0 ? expiredCount : 0,
        ),
      );

      final expiringSubscriptions = expiringList
          .map<ExpiringSubscription>((item) {
        final data = item as Map<String, dynamic>;
        return ExpiringSubscription(
          memberId: data['memberId']?.toString() ??
                    data['member_id']?.toString() ??
                    data['userId']?.toString() ??
                    data['user_id']?.toString() ?? '',
          memberName: data['memberName']?.toString() ??
                      data['member_name']?.toString() ??
                      data['fullName']?.toString() ??
                      data['full_name']?.toString() ?? '',
          email: data['email']?.toString() ?? '',
          phone: data['phone']?.toString() ?? '',
          expiryDate: DateTime.tryParse(
                data['expiryDate']?.toString() ??
                data['expiry_date']?.toString() ?? '',
              ) ?? DateTime.now(),
          status: data['status']?.toString() ?? '',
        );
      }).toList();

      print('✅ Dashboard loaded - Expiring count: ${stats.expiringSubscriptions}');

      state = state.copyWith(
        isLoading: false,
        stats: stats,
        expiringSubscriptions: expiringSubscriptions,
        errorMessage: null,
      );
    } catch (e) {
      print('❌ Dashboard error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load dashboard data: ${e.toString()}',
      );
    }
  }

  int _extractInt(dynamic data, List<String> keys) {
    if (data is! Map<String, dynamic>) return 0;

    for (final key in keys) {
      if (key.contains('.')) {
        final parts = key.split('.');
        dynamic current = data;
        for (final part in parts) {
          if (current is Map<String, dynamic> && current.containsKey(part)) {
            current = current[part];
          } else {
            current = null;
            break;
          }
        }
        if (current != null) {
          return (current is int) ? current : int.tryParse(current.toString()) ?? 0;
        }
      } else if (data.containsKey(key)) {
        final value = data[key];
        return (value is int) ? value : int.tryParse(value.toString()) ?? 0;
      }
    }
    return 0;
  }

  dynamic _extractValue(dynamic data, List<String> keys) {
    if (data is! Map<String, dynamic>) return null;

    for (final key in keys) {
      if (data.containsKey(key)) {
        return data[key];
      }
    }
    return null;
  }

  List<RevenueData> _extractRevenueTrend(dynamic data) {
    if (data is! Map<String, dynamic>) return [];

    final trendData = data['revenueTrend'] ?? data['revenue_trend'];
    if (trendData is! List) return [];

    return trendData.map<RevenueData>((item) {
      final itemData = item as Map<String, dynamic>;
      return RevenueData(
        month: itemData['month']?.toString() ?? '',
        amount: (itemData['amount'] ?? 0).toDouble(),
      );
    }).toList();
  }

  Future<void> refreshDashboard() async {
    await _initializeDashboard();
  }

  void runExpiryCheck() {
    // Simulate expiry check
    state = state.copyWith(hasExpired: true);
  }
}

final dashboardViewModelProvider =
    StateNotifierProvider<DashboardViewModel, DashboardState>((ref) {
  return DashboardViewModel(ref.read(apiServiceProvider));
});
