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

      final stats = DashboardStats(
        activeMembers: (statsData['activeMembers'] ?? 0).toInt(),
        expiringSubscriptions: (statsData['expiringSubscriptions'] ?? 0).toInt(),
        expiredSubscriptions: (statsData['expiredSubscriptions'] ?? 0).toInt(),
        monthlyRevenue: '\$${statsData['monthlyRevenue'] ?? '0'}',
        renewalRate: '${statsData['renewalRate'] ?? '0'}%',
        revenueTrend: (statsData['revenueTrend'] as List?)
                ?.map<RevenueData>((item) {
              final data = item as Map<String, dynamic>;
              return RevenueData(
                month: data['month']?.toString() ?? '',
                amount: (data['amount'] ?? 0).toDouble(),
              );
            }).toList() ??
            [],
        membershipBreakdown: MembershipBreakdown(
          active: (statsData['membershipBreakdown']?['active'] ?? 0).toInt(),
          expiring: (statsData['membershipBreakdown']?['expiring'] ?? 0).toInt(),
          expired: (statsData['membershipBreakdown']?['expired'] ?? 0).toInt(),
        ),
      );

      final expiringList = (expiringData as List?)
              ?.map<ExpiringSubscription>((item) {
            final data = item as Map<String, dynamic>;
            return ExpiringSubscription(
              memberId: data['memberId']?.toString() ?? data['member_id']?.toString() ?? '',
              memberName: data['memberName']?.toString() ?? data['member_name']?.toString() ?? '',
              email: data['email']?.toString() ?? '',
              phone: data['phone']?.toString() ?? '',
              expiryDate: DateTime.tryParse(
                    data['expiryDate']?.toString() ?? data['expiry_date']?.toString() ?? '',
                  ) ??
                  DateTime.now(),
              status: data['status']?.toString() ?? '',
            );
          }).toList() ??
          [];

      state = state.copyWith(
        isLoading: false,
        stats: stats,
        expiringSubscriptions: expiringList,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load dashboard data',
      );
    }
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
