import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../services/face_embedding_service.dart';

class Member {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String? faceImage;  // URL stored in database
  final String? faceEmbedding;  // Double precision embedding stored as comma-separated string
  final String? password;
  final DateTime createdAt;

  Member({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.faceImage,
    this.faceEmbedding,
    this.password,
    required this.createdAt,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      fullName: (json['full_name'] ?? json['fullName'] ?? json['name'] ?? '')
          .toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? json['phone_number'] ?? '').toString(),
      faceImage: json['face_image']?.toString() ?? json['faceImage']?.toString(),
      faceEmbedding: json['face_embedding']?.toString() ?? json['faceEmbedding']?.toString(),
      createdAt: DateTime.tryParse(
            (json['created_at'] ?? json['createdAt'] ?? '').toString(),
          ) ??
          DateTime.now(),
    );
  }

  Member copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? faceImage,
    String? faceEmbedding,
    String? password,
    DateTime? createdAt,
  }) {
    return Member(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      faceImage: faceImage ?? this.faceImage,
      faceEmbedding: faceEmbedding ?? this.faceEmbedding,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class MembersState {
  final List<Member> members;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final bool isAddingMember;

  MembersState({
    this.members = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.isAddingMember = false,
  });

  MembersState copyWith({
    List<Member>? members,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    bool? isAddingMember,
  }) {
    return MembersState(
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      isAddingMember: isAddingMember ?? this.isAddingMember,
    );
  }

  List<Member> get filteredMembers {
    if (searchQuery.isEmpty) return members;
    return members
        .where((member) =>
            member.fullName.toLowerCase().contains(searchQuery.toLowerCase()) ||
            member.email.toLowerCase().contains(searchQuery.toLowerCase()) ||
            member.phone.contains(searchQuery))
        .toList();
  }
}

class MembersViewModel extends StateNotifier<MembersState> {
  MembersViewModel(this._api) : super(MembersState(isLoading: true)) {
    _initializeMembers();
  }

  final ApiService _api;

  Future<void> _initializeMembers() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final data = await _api.getMembers();

      // Parse members from response
      List<dynamic> membersList = data is List ? data : [];

      final members = membersList
          .map((json) {
            if (json is Map<String, dynamic>) {
              return Member.fromJson(json);
            } else if (json is Map) {
              return Member.fromJson(json.cast<String, dynamic>());
            }
            return null;
          })
          .whereType<Member>()
          .toList();

      state = state.copyWith(
        isLoading: false,
        members: members,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load members',
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }

  Future<void> addMember({
    required String fullName,
    required String email,
    required String phone,
    File? faceImageFile,
    String? password,
  }) async {
    try {
      state = state.copyWith(isAddingMember: true, errorMessage: null);

      if (fullName.isEmpty) {
        state = state.copyWith(
          isAddingMember: false,
          errorMessage: 'Please enter full name',
        );
        return;
      }

      if (email.isEmpty || !email.contains('@')) {
        state = state.copyWith(
          isAddingMember: false,
          errorMessage: 'Please enter valid email',
        );
        return;
      }

      if (phone.isEmpty) {
        state = state.copyWith(
          isAddingMember: false,
          errorMessage: 'Please enter phone number',
        );
        return;
      }

      // Extract face embedding if image is provided
      String? faceEmbeddingString;
      if (faceImageFile != null && faceImageFile.existsSync()) {
        try {
          final embedding =
              await FaceEmbeddingService.extractFaceEmbedding(faceImageFile);

          // Validate embedding
          if (FaceEmbeddingService.isValidEmbedding(embedding)) {
            // Serialize embedding to double precision string format
            faceEmbeddingString =
                FaceEmbeddingService.serializeEmbedding(embedding);
          }
        } catch (e) {
          // Log embedding extraction error but continue with member creation
          // Silently fail - member still created without embedding
        }
      }

      final created = await _api.createMember(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        faceImage: faceImageFile,
      );

      // Add embedding data to response if we extracted it locally
      if (faceEmbeddingString != null && !created.containsKey('face_embedding')) {
        created['face_embedding'] = faceEmbeddingString;
      }

      final newMember = Member.fromJson(created);

      state = state.copyWith(
        isAddingMember: false,
        members: [...state.members, newMember],
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isAddingMember: false,
        errorMessage: 'Failed to add member: ${e.toString()}',
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<void> refresh() async {
    await _initializeMembers();
  }
}

final membersViewModelProvider =
    StateNotifierProvider<MembersViewModel, MembersState>((ref) {
  return MembersViewModel(ref.read(apiServiceProvider));
});
