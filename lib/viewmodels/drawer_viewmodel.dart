import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    this.userName = 'pakam chandana',
    this.userRole = 'Owner',
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
  DrawerViewModel() : super(DrawerState());

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
  return DrawerViewModel();
});

