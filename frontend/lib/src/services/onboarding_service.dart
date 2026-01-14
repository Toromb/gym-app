import '../services/api_client.dart';
import '../models/onboarding_model.dart';

class OnboardingService {
  final ApiClient _client;

  OnboardingService(this._client);

  Future<bool> getMyStatus() async {
    try {
      // ApiClient throws on error (4xx, 5xx), returns JSON body on success
      final data = await _client.get('/users/onboarding/status');
      if (data is Map && data['hasCompletedOnboarding'] == true) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error checking onboarding status: $e');
      return false; 
    }
  }

  Future<void> submitOnboarding(CreateOnboardingDto dto) async {
    // Post returns parsed JSON or null
    await _client.post(
      '/users/onboarding',
      dto.toJson(),
    );
  }

  Future<OnboardingProfile?> getUserOnboarding(String userId) async {
    try {
      final data = await _client.get('/users/onboarding/user/$userId');
      if (data != null && data['hasCompletedOnboarding'] == true && data['profile'] != null) {
          return OnboardingProfile.fromJson(data['profile']);
      }
      return null;
    } catch (e) {
      print('Error fetching user onboarding: $e');
      return null;
    }
  }
}
