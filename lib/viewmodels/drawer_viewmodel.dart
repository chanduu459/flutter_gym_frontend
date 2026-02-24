import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'login_viewmodel.dart';

enum MenuItem {
  dashboard,
  members,
  attendance,
  plans,
  subscriptions,
  notifications,
  settings,
  logout,
}

class DrawerState {
  final MenuItem? selectedItem;
  final bool isDrawerOpen;
  final String userName;
  final String userRole;

  DrawerState({
    this.selectedItem,
    this.isDrawerOpen = false,
    this.userName = 'Guest',
    this.userRole = 'User',
  });

  DrawerState copyWith({
    MenuItem? selectedItem,
    bool? isDrawerOpen,
    String? userName,
    String? userRole,
  }) {
    return DrawerState(
      selectedItem: selectedItem ?? this.selectedItem,
      isDrawerOpen: isDrawerOpen ?? this.isDrawerOpen,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
    );
  }
}

class DrawerViewModel extends StateNotifier<DrawerState> {
  DrawerViewModel(this._ref) : super(DrawerState()) {
    _loadUserData();
  }

  final Ref _ref;

  void _loadUserData() {
    // Watch login state to get user data
    final loginState = _ref.read(loginViewModelProvider);
    if (loginState.userName != null && loginState.userRole != null) {
      state = state.copyWith(
        userName: loginState.userName,
        userRole: loginState.userRole,
      );
    }
  }

  void updateUserData(String? userName, String? userRole) {
    if (userName != null && userRole != null) {
      state = state.copyWith(
        userName: userName,
        userRole: userRole,
      );
    }
  }

  void toggleDrawer() {
    state = state.copyWith(isDrawerOpen: !state.isDrawerOpen);
  }

  void openDrawer() {
    state = state.copyWith(isDrawerOpen: true);
  }

  void closeDrawer() {
    state = state.copyWith(isDrawerOpen: false);
  }

  void selectMenuItem(MenuItem item) {
    state = state.copyWith(selectedItem: item, isDrawerOpen: false);
  }

  void logout() {
    // Clear any auth data here
    state = DrawerState();
  }
}

final drawerViewModelProvider =
    StateNotifierProvider<DrawerViewModel, DrawerState>((ref) {
  return DrawerViewModel(ref);
});

