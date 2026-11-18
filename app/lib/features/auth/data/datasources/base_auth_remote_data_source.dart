import 'package:app/features/auth/data/models/account_status_response.dart';
import 'package:app/features/auth/data/models/verify_code_response.dart';
import 'package:app/features/auth/domain/entities/code_request.dart';

/// Sends base auth requests to the API.
abstract class BaseAuthRemoteDataSource {
  /// Requests an OTP for [phone] and returns its verification identifier and
  /// the wait before the next code. An existing [verificationId] resends
  /// within the same request.
  Future<CodeRequest> requestCode(String phone, {String? verificationId});

  /// Verifies an OTP and returns the session tokens and profile state.
  Future<VerifyCodeResponse> verifyCode({
    required String verificationId,
    required String code,
  });

  /// Revokes the current session through POST /api/v1/auth/sign-out.
  Future<void> signOut();

  /// Checks the current session; token renewal is handled by the interceptor.
  Future<AccountStatusResponse> checkSession();
}
