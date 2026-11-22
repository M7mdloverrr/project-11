import '../models/profile.dart';

abstract interface class ProfileRepository {
  /// Profile of the signed-in user, or null if the row is missing.
  Future<Profile?> fetchProfile(String userId);

  Future<Profile> updateProfile(String userId, {String? displayName, String? locale});
}
