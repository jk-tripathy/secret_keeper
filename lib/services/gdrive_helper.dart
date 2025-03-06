import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart'
    as desktop;
import 'package:google_sign_in/google_sign_in.dart' as mobile;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path_provider/path_provider.dart';

class GdriveHelper {
  static desktop.GoogleSignIn? desktopSignIn;
  static mobile.GoogleSignIn? mobileSignIn;
  static mobile.GoogleSignInAccount? mobileUser;

  static void init() {
    if (Platform.isAndroid || Platform.isIOS) {
      mobileSignIn = mobile.GoogleSignIn(
        scopes: ['https://www.googleapis.com/auth/drive.file'],
      );
    } else {
      desktopSignIn = desktop.GoogleSignIn(
        params: desktop.GoogleSignInParams(
          clientId:
              "349665046436-soifv22hqcar5mcm712tamb2m83gloc8.apps.googleusercontent.com",
          clientSecret: dotenv.env["clientSecret"],
          redirectPort: 42069,
          scopes: ['https://www.googleapis.com/auth/drive.file'],
        ),
      );
    }
  }

  static Future<void> signIn() async {
    init();
    if (Platform.isAndroid || Platform.isIOS) {
      mobileUser = await mobileSignIn!.signIn();
    } else {
      await desktopSignIn!.signIn();
    }
  }

  static Future<void> signInSilently() async {
    init();
    if (Platform.isAndroid || Platform.isIOS) {
      mobileUser = await mobileSignIn!.signInSilently();
    } else {
      await desktopSignIn!.signInOffline();
    }
  }

  static Future<void> signOut() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await mobileSignIn!.disconnect();
    } else {
      await desktopSignIn!.signOut();
    }
  }

  static Future<drive.DriveApi> getDriveClient() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final mobile.GoogleSignInAuthentication googleAuth =
          await mobileUser!.authentication;
      final auth.AuthClient authClient = auth.authenticatedClient(
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
      return drive.DriveApi(authClient);
    } else {
      http.Client? authClient = await desktopSignIn!.authenticatedClient;
      if (authClient == null) {
        throw Exception('Failed to authenticate with Google');
      }
      return drive.DriveApi(authClient);
    }
  }

  static Future<String> computeFileHash(String filePath) async {
    var file = File(filePath);
    var bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  static Future<String> getDatabasePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/passwords.db'; // Change to match your SQLite DB name
  }

  static Future<(dynamic, dynamic)> getMetadata(
    drive.DriveApi driveClient,
  ) async {
    final metadataFileList = await driveClient.files.list(
      q: "name='backup_metadata.json'",
    );
    if (metadataFileList.files != null && metadataFileList.files!.isNotEmpty) {
      final metadataFile = metadataFileList.files!.first;
      final metadataStream =
          await driveClient.files.get(
                metadataFile.id!,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;
      final metadataBytes = await metadataStream.stream.first;
      final metadataJson = jsonDecode(utf8.decode(metadataBytes));
      return (metadataJson, metadataFile);
    }

    return (null, null);
  }

  static Future<bool> checkMetadata() async {
    final drive.DriveApi driveClient = await getDriveClient();
    final (metadataJson, _) = await getMetadata(driveClient);
    final curHash = await computeFileHash(await getDatabasePath());
    if (metadataJson != null) {
      final newHash = metadataJson["hash"];
      if (curHash != newHash) {
        return true;
      }
    }

    return false;
  }

  static Future<void> uploadBackup({bool init = false}) async {
    final drive.DriveApi driveClient = await getDriveClient();
    final String dbPath = await getDatabasePath();
    final String newHash = await computeFileHash(dbPath);
    final String? folderId = await getOrCreateFolder("SecretKeeper");

    // await DatabaseHelper().closeDatabase();
    final fileList = await driveClient.files.list(
      q: "'$folderId' in parents and name='latest_backup.db'",
    );
    if (fileList.files != null && fileList.files!.isNotEmpty) {
      final existingFile = fileList.files!.first;
      final (metadataJson, metadataFile) = await getMetadata(driveClient);
      if (metadataJson != null && metadataFile != null) {
        final oldHash = metadataJson["hash"];
        if (oldHash == newHash && !init) {
          return;
        }
        await driveClient.files.delete(existingFile.id!);
        await driveClient.files.delete(metadataFile.id!);
      }
    }

    // Upload new backup
    var file = drive.File();
    file.name = "latest_backup.db";
    file.parents = [folderId!];
    final media = drive.Media(
      File(dbPath).openRead(),
      File(dbPath).lengthSync(),
    );
    await driveClient.files.create(file, uploadMedia: media);

    // Upload metadata
    var metadata = drive.File();
    metadata.name = "backup_metadata.json";
    metadata.parents = [folderId];
    final metadataContent = jsonEncode({"hash": newHash});
    final metadataMedia = drive.Media(
      Stream.value(utf8.encode(metadataContent)),
      metadataContent.length,
    );
    await driveClient.files.create(metadata, uploadMedia: metadataMedia);
  }

  static Future<void> restoreBackup() async {
    final driveClient = await getDriveClient();
    final dbPath = await getDatabasePath();
    final String curHash = await computeFileHash(dbPath);
    final folderId = await getOrCreateFolder("SecretKeeper");

    // await DatabaseHelper().closeDatabase();
    final fileList = await driveClient.files.list(
      q: "'$folderId' in parents and name='latest_backup.db'",
    );
    if (fileList.files == null || fileList.files!.isEmpty) {
      uploadBackup();
    } else {
      final (metadataJson, _) = await getMetadata(driveClient);
      if (metadataJson != null) {
        if (metadataJson["hash"] == curHash) {
          return;
        } else {
          final backupFile = fileList.files!.first;
          final mediaStream =
              await driveClient.files.get(
                    backupFile.id!,
                    downloadOptions: drive.DownloadOptions.fullMedia,
                  )
                  as drive.Media;
          final fileBytes = await mediaStream.stream.fold<List<int>>(
            <int>[],
            (previous, element) => previous..addAll(element),
          );
          File(dbPath).writeAsBytesSync(fileBytes);
        }
      }
    }
  }

  static Future<String?> getOrCreateFolder(String folderName) async {
    final driveClient = await getDriveClient();
    try {
      // Search for an existing folder with the same name
      final folderList = await driveClient.files.list(
        q: "mimeType='application/vnd.google-apps.folder' and name='$folderName'",
      );

      if (folderList.files != null && folderList.files!.isNotEmpty) {
        return folderList.files!.first.id;
      }

      // If folder does not exist, create it
      var folder = drive.File();
      folder.name = folderName;
      folder.mimeType = "application/vnd.google-apps.folder";

      final createdFolder = await driveClient.files.create(folder);
      return createdFolder.id;
    } catch (e) {
      return null;
    }
  }
}
