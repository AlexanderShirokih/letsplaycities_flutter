import 'authentication/authentication.dart';
import 'account_manager.dart';

/// Test implementation
class StubAccountManager extends AccountManager {
  @override
  RemoteAccountInfo getLastSignedInAccount() => RemoteAccountInfo(
        name: 'Test',
        credential: Credential(accessToken: "i'mapass", userId: 30955),
        pictureUri: null,
        canReceiveMessages: false,
      );

  //TODO:
  @override
  Future<RemoteAccountInfo> signIn() => throw ('Unimplemented!');

  // TODO:
  @override
  Future signOut() => throw ('Unimplemented');

  @override
  bool isSignedIn() => true;

  // TODO: Implement updatePicture
  @override
  Future<void> updatePicture() => throw ('Unimplemented');
}