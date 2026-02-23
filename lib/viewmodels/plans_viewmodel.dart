import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class Plan {
  final String id;
  final String name;
  final double price;
  final int durationDays;
  final String description;
  final bool isActive;

  Plan({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.description,
    this.isActive = true,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to double
    double parsePrice(dynamic priceValue) {
      if (priceValue == null) return 0.0;
      if (priceValue is double) return priceValue;
      if (priceValue is int) return priceValue.toDouble();
      if (priceValue is String) {
        return double.tryParse(priceValue) ?? 0.0;
      }
      return 0.0;
    }

    // Helper function to safely convert to int
    int parseDuration(dynamic durationValue) {
      if (durationValue == null) return 0;
      if (durationValue is int) return durationValue;
      if (durationValue is double) return durationValue.toInt();
      if (durationValue is String) {
        return int.tryParse(durationValue) ?? 0;
      }
      return 0;
    }

    return Plan(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? json['plan_name'] ?? '').toString(),
      price: parsePrice(json['price'] ?? json['plan_price']),
      durationDays: parseDuration(json['duration_days'] ?? json['durationDays']),
      description: (json['description'] ?? '').toString(),
      isActive: (json['is_active'] ?? json['isActive'] ?? true) == true,
    );
  }
}

class PlansState {
  final List<Plan> plans;
  final bool isLoading;
  final bool isAddingPlan;
  final String? errorMessage;

  PlansState({
    this.plans = const [],
    this.isLoading = false,
    this.isAddingPlan = false,
    this.errorMessage,
  });

  PlansState copyWith({
    List<Plan>? plans,
    bool? isLoading,
    bool? isAddingPlan,
    String? errorMessage,
  }) {
    return PlansState(
      plans: plans ?? this.plans,
      isLoading: isLoading ?? this.isLoading,
      isAddingPlan: isAddingPlan ?? this.isAddingPlan,
      errorMessage: errorMessage,
    );
  }
}

class PlansViewModel extends StateNotifier<PlansState> {
  PlansViewModel(this._api) : super(PlansState(isLoading: true)) {
    _initializePlans();
  }

  final ApiService _api;

  Future<void> _initializePlans() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final data = await _api.getPlans();

      // Handle different response formats
      List<dynamic> plansList = [];
      if (data is List) {
        plansList = data;
      } else if (data is Map) {
        final mapData = data as Map<String, dynamic>;
        if (mapData.containsKey('plans')) {
          plansList = mapData['plans'] as List<dynamic>;
        }
      }

      if (plansList.isEmpty && data is! List) {
        throw ApiException('Invalid response format from server');
      }

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

      state = state.copyWith(
        plans: plans,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<bool> addPlan({
    required String name,
    required double? price,
    required int? durationDays,
    required String description,
  }) async {
    if (name.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Plan name is required');
      return false;
    }
    if (price == null || price <= 0) {
      state = state.copyWith(errorMessage: 'Enter a valid price');
      return false;
    }
    if (durationDays == null || durationDays <= 0) {
      state = state.copyWith(errorMessage: 'Enter a valid duration');
      return false;
    }

    try {
      state = state.copyWith(isAddingPlan: true, errorMessage: null);

      final created = await _api.createPlan(
        name: name.trim(),
        price: price,
        durationDays: durationDays,
        description: description.trim(),
      );
      final newPlan = Plan.fromJson(created);

      state = state.copyWith(
        plans: [newPlan, ...state.plans],
        isAddingPlan: false,
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        isAddingPlan: false,
        errorMessage: 'Failed to add plan',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<void> refresh() async {
    await _initializePlans();
  }
}

final plansViewModelProvider =
    StateNotifierProvider<PlansViewModel, PlansState>((ref) {
  return PlansViewModel(ref.read(apiServiceProvider));
});
