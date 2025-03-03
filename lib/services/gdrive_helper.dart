import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:googleapis/drive/v3.dart' as drive;

class GdriveHelper {
  static final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/drive.file'],
  );
  static GoogleSignInAccount? googleUser;
  static auth.AuthClient? authClient;
  // static Map<String, String> headers = {};

  static Future<void> signIn() async {
    googleUser = await googleSignIn.signInSilently();
    googleUser ??= await googleSignIn.signIn();
  }

  static Future<void> signOut() async {
    await googleSignIn.disconnect();
  }

  static Future<drive.DriveApi> getDriveClient() async {
    final GoogleSignInAuthentication googleAuth =
        await googleUser!.authentication;
    authClient = auth.authenticatedClient(
      http.Client(),
      auth.AccessCredentials(
        auth.AccessToken(
          'Bearer',
          googleAuth.accessToken!,
          DateTime.now().toUtc(),
        ),
        null,
        ['https://www.googleapis.com/auth/drive.file'],
      ),
    );
    if (authClient == null) {
      throw Exception('Failed to authenticate with Google');
    }
    return drive.DriveApi(authClient!);
  }

  static Future<void> init() async {
    signIn();
  }

  static Future<void> uploadFile() async {
    final drive.DriveApi driveClient = await getDriveClient();
    final drive.File file = drive.File();
    file.name = 'test.txt';
    file.parents = ['root'];
    final drive.File? uploadedFile = await driveClient.files.create(
      file,
      uploadMedia: drive.Media(
        Stream.fromIterable([
          [104, 101, 108, 108, 111, 32, 119, 111, 114, 108, 100],
        ]),
        11,
      ),
    );
    print(uploadedFile!.id);
  }
}
