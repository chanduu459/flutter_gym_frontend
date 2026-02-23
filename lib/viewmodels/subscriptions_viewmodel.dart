import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class SelectionOption {
  final String id;
  final String label;

  SelectionOption({required this.id, required this.label});
}

class Subscription {
  final String id;
  final String memberName;
  final String planName;
  final DateTime startDate;

  Subscription({
    required this.id,
    required this.memberName,
    required this.planName,
    required this.startDate,
  });

  Subscription copyWith({
    String? id,
    String? memberName,
    String? planName,
    DateTime? startDate,
  }) {
    return Subscription(
      id: id ?? this.id,
      memberName: memberName ?? this.memberName,
      planName: planName ?? this.planName,
      startDate: startDate ?? this.startDate,
    );
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    final member = json['member'] as Map<String, dynamic>?;
    final plan = json['plan'] as Map<String, dynamic>?;

    // Extract member name from various possible field names
    String memberNameValue = '';
    if (member != null) {
      memberNameValue = (member['full_name'] ??
                        member['fullName'] ??
                        member['name'] ??
                        '').toString();
    }

    // If not found in member object, try direct fields
    if (memberNameValue.isEmpty) {
      memberNameValue = (json['member_name'] ??
                        json['memberName'] ??
                        json['full_name'] ??
                        json['fullName'] ??
                        json['name'] ??
                        '').toString();
    }

    // Extract plan name from various possible field names
    String planNameValue = '';
    if (plan != null) {
      planNameValue = (plan['name'] ??
                      plan['plan_name'] ??
                      '').toString();
    }

    // If not found in plan object, try direct fields
    if (planNameValue.isEmpty) {
      planNameValue = (json['plan_name'] ??
                      json['planName'] ??
                      json['name'] ??
                      '').toString();
    }

    return Subscription(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      memberName: memberNameValue,
      planName: planNameValue,
      startDate: DateTime.tryParse(
            (json['start_date'] ?? json['startDate'] ?? '').toString(),
          ) ??
          DateTime.now(),
    );
  }
}

class SubscriptionsState {
  final List<Subscription> subscriptions;
  final List<SelectionOption> members;
  final List<SelectionOption> plans;
  final bool isLoading;
  final bool isAddingSubscription;
  final String? errorMessage;
  final String searchQuery;

  SubscriptionsState({
    this.subscriptions = const [],
    this.members = const [],
    this.plans = const [],
    this.isLoading = false,
    this.isAddingSubscription = false,
    this.errorMessage,
    this.searchQuery = '',
  });

  SubscriptionsState copyWith({
    List<Subscription>? subscriptions,
    List<SelectionOption>? members,
    List<SelectionOption>? plans,
    bool? isLoading,
    bool? isAddingSubscription,
    String? errorMessage,
    String? searchQuery,
  }) {
    return SubscriptionsState(
      subscriptions: subscriptions ?? this.subscriptions,
      members: members ?? this.members,
      plans: plans ?? this.plans,
      isLoading: isLoading ?? this.isLoading,
      isAddingSubscription: isAddingSubscription ?? this.isAddingSubscription,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class SubscriptionsViewModel extends StateNotifier<SubscriptionsState> {
  SubscriptionsViewModel(this._api) : super(SubscriptionsState(isLoading: true)) {
    _initializeSubscriptions();
  }

  final ApiService _api;

  Future<void> _initializeSubscriptions() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final subscriptionsData = await _api.getSubscriptions();
      final membersData = await _api.getMembers();
      final plansData = await _api.getPlans();

      // Parse members with flexible response format handling
      List<dynamic> membersList = [];
      if (membersData is List) {
        membersList = membersData;
      } else if (membersData is Map) {
        final mapData = membersData as Map<String, dynamic>;
        if (mapData.containsKey('members')) {
          membersList = mapData['members'] as List<dynamic>;
        }
      }

      final members = membersList
          .map((json) {
            if (json is Map) {
              final data = json is Map<String, dynamic>
                  ? json
                  : (json as Map).cast<String, dynamic>();
              return SelectionOption(
                id: (data['id'] ?? data['_id'] ?? '').toString(),
                label: (data['full_name'] ?? data['fullName'] ?? data['name'] ?? '')
                    .toString(),
              );
            }
            return null;
          })
          .whereType<SelectionOption>()
          .where((option) => option.id.isNotEmpty && option.label.isNotEmpty)
          .toList();

      // Parse plans with flexible response format handling
      List<dynamic> plansList = [];
      if (plansData is List) {
        plansList = plansData;
      } else if (plansData is Map) {
        final mapData = plansData as Map<String, dynamic>;
        if (mapData.containsKey('plans')) {
          plansList = mapData['plans'] as List<dynamic>;
        }
      }

      final plans = plansList
          .map((json) {
            if (json is Map) {
              final data = json is Map<String, dynamic>
                  ? json
                  : (json as Map).cast<String, dynamic>();
              return SelectionOption(
                id: (data['id'] ?? data['_id'] ?? '').toString(),
                label: (data['name'] ?? data['plan_name'] ?? '').toString(),
              );
            }
            return null;
          })
          .whereType<SelectionOption>()
          .where((option) => option.id.isNotEmpty && option.label.isNotEmpty)
          .toList();

      // Parse subscriptions with flexible response format handling
      List<dynamic> subscriptionsList = [];
      if (subscriptionsData is List) {
        subscriptionsList = subscriptionsData;
      } else if (subscriptionsData is Map) {
        final mapData = subscriptionsData as Map<String, dynamic>;
        if (mapData.containsKey('subscriptions')) {
          subscriptionsList = mapData['subscriptions'] as List<dynamic>;
        }
      }

      final subscriptions = subscriptionsList
          .map((json) {
            if (json is Map<String, dynamic>) {
              var subscription = Subscription.fromJson(json);

              // If member name is empty, try to find it from the members list using userId
              if (subscription.memberName.isEmpty) {
                final userId = (json['user_id'] ?? json['userId'] ?? json['member_id'] ?? json['memberId'] ?? '').toString();
                if (userId.isNotEmpty) {
                  final matchingMember = members.firstWhere(
                    (member) => member.id == userId,
                    orElse: () => SelectionOption(id: '', label: ''),
                  );
                  if (matchingMember.label.isNotEmpty) {
                    subscription = subscription.copyWith(memberName: matchingMember.label);
                  }
                }
              }

              // If plan name is empty, try to find it from the plans list using planId
              if (subscription.planName.isEmpty) {
                final planId = (json['plan_id'] ?? json['planId'] ?? '').toString();
                if (planId.isNotEmpty) {
                  final matchingPlan = plans.firstWhere(
                    (plan) => plan.id == planId,
                    orElse: () => SelectionOption(id: '', label: ''),
                  );
                  if (matchingPlan.label.isNotEmpty) {
                    subscription = subscription.copyWith(planName: matchingPlan.label);
                  }
                }
              }

              return subscription;
            } else if (json is Map) {
              return Subscription.fromJson(json.cast<String, dynamic>());
            }
            return null;
          })
          .whereType<Subscription>()
          .toList();

      state = state.copyWith(
        subscriptions: subscriptions,
        members: members,
        plans: plans,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load subscriptions',
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> addSubscription({
    required SelectionOption? member,
    required SelectionOption? plan,
    required DateTime? startDate,
  }) async {
    if (member == null) {
      state = state.copyWith(errorMessage: 'Select a member');
      return false;
    }
    if (plan == null) {
      state = state.copyWith(errorMessage: 'Select a plan');
      return false;
    }
    if (startDate == null) {
      state = state.copyWith(errorMessage: 'Select a start date');
      return false;
    }

    try {
      state = state.copyWith(isAddingSubscription: true, errorMessage: null);

      // Create subscription on backend
      final created = await _api.createSubscription(
        userId: member.id,
        planId: plan.id,
        startDate: startDate.toIso8601String(),
      );

      // Create subscription object with selected member and plan names
      final newSubscription = Subscription(
        id: (created['id'] ?? created['_id'] ?? '').toString(),
        memberName: member.label, // Use the label from selected member option
        planName: plan.label,     // Use the label from selected plan option
        startDate: startDate,
      );

      // Add to the list immediately for UI responsiveness
      state = state.copyWith(
        subscriptions: [newSubscription, ...state.subscriptions],
        isAddingSubscription: false,
        errorMessage: null,
      );

      // Then refresh to ensure data consistency with backend
      await _initializeSubscriptions();

      return true;
    } catch (e) {
      state = state.copyWith(
        isAddingSubscription: false,
        errorMessage: 'Failed to add subscription',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<void> refresh() async {
    await _initializeSubscriptions();
  }

  List<Subscription> get filteredSubscriptions {
    final query = state.searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return state.subscriptions;
    }
    return state.subscriptions.where((subscription) {
      return subscription.memberName.toLowerCase().contains(query) ||
          subscription.planName.toLowerCase().contains(query);
    }).toList();
  }
}

final subscriptionsViewModelProvider =
    StateNotifierProvider<SubscriptionsViewModel, SubscriptionsState>((ref) {
  return SubscriptionsViewModel(ref.read(apiServiceProvider));
});
