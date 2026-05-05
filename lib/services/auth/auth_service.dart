import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis_auth/googleapis_auth.dart' show AuthClient;

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  // SAFETY: Drive access is intentionally excluded from Phase 1 scopes.
  // The app may only read and write data within the wedding planner spreadsheet.
  // It cannot create, move, or delete any file or folder on Google Drive.
  // If Drive browsing is added in Phase 2, use drive.readonly — never drive or drive.file
  // with delete capabilities.
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/spreadsheets',
    ],
  );

  GoogleSignIn get googleSignIn => _googleSignIn;

  Future<GoogleSignInAccount?> silentSignIn() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (_) {
      return null;
    }
  }

  Future<GoogleSignInAccount?> signIn() async {
    return await _googleSignIn.signIn();
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<AuthClient?> getAuthClient() async {
    return await _googleSignIn.authenticatedClient();
  }

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  Stream<GoogleSignInAccount?> get onAuthStateChanged =>
      _googleSignIn.onCurrentUserChanged;
}
