import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'database_service.dart';

/// Cloud storage service for user data backup
/// Users control where their data is stored - local or cloud
class CloudStorageService {
  static const List<String> _scopes = [drive.DriveApi.driveFileScope];

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: _scopes,
  );

  /// Backup database to Google Drive
  static Future<String?> backupToGoogleDrive() async {
    try {
      // Sign in to Google
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return null; // User cancelled
      }

      // Get authentication
      final googleAuth = await account.authentication;
      final credentials = AccessCredentials(
        AccessToken('Bearer', googleAuth.accessToken!, DateTime.now().add(const Duration(hours: 1))),
        null,
        _scopes,
      );

      // Create Drive API client
      final client = authenticatedClient(
        Client(),
        credentials,
      );
      final driveApi = drive.DriveApi(client);

      // Export database
      final dbFile = await DatabaseService.exportDatabase();

      // Create file metadata
      final driveFile = drive.File()
        ..name = 'hwy_tms_backup_${DateTime.now().toIso8601String()}.db'
        ..description = 'HWY-TMS Database Backup'
        ..mimeType = 'application/octet-stream';

      // Upload to Drive
      final media = drive.Media(dbFile.openRead(), dbFile.lengthSync());
      final response = await driveApi.files.create(
        driveFile,
        uploadMedia: media,
      );

      client.close();

      return response.id;
    } catch (e) {
      print('❌ Google Drive backup failed: $e');
      return null;
    }
  }

  /// Restore database from Google Drive
  static Future<bool> restoreFromGoogleDrive(String fileId) async {
    try {
      // Sign in to Google
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return false;
      }

      // Get authentication
      final googleAuth = await account.authentication;
      final credentials = AccessCredentials(
        AccessToken('Bearer', googleAuth.accessToken!, DateTime.now().add(const Duration(hours: 1))),
        null,
        _scopes,
      );

      // Create Drive API client
      final client = authenticatedClient(
        Client(),
        credentials,
      );
      final driveApi = drive.DriveApi(client);

      // Download file
      final media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/restore_backup.db');

      final sink = tempFile.openWrite();
      await media.stream.pipe(sink);
      await sink.close();

      // Import database
      await DatabaseService.importDatabase(tempFile.path);

      client.close();
      await tempFile.delete();

      return true;
    } catch (e) {
      print('❌ Google Drive restore failed: $e');
      return false;
    }
  }

  /// List backups from Google Drive
  static Future<List<drive.File>> listBackups() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return [];
      }

      final googleAuth = await account.authentication;
      final credentials = AccessCredentials(
        AccessToken('Bearer', googleAuth.accessToken!, DateTime.now().add(const Duration(hours: 1))),
        null,
        _scopes,
      );

      final client = authenticatedClient(
        Client(),
        credentials,
      );
      final driveApi = drive.DriveApi(client);

      // Query for HWY-TMS backup files
      final fileList = await driveApi.files.list(
        q: "name contains 'hwy_tms_backup' and trashed=false",
        orderBy: 'createdTime desc',
        spaces: 'drive',
      );

      client.close();

      return fileList.files ?? [];
    } catch (e) {
      print('❌ Failed to list Google Drive backups: $e');
      return [];
    }
  }

  /// Backup to local storage (for manual export)
  static Future<File> backupToLocal() async {
    return await DatabaseService.exportDatabase();
  }

  /// Restore from local file
  static Future<bool> restoreFromLocal(String filePath) async {
    try {
      await DatabaseService.importDatabase(filePath);
      return true;
    } catch (e) {
      print('❌ Local restore failed: $e');
      return false;
    }
  }

  /// Sign out from Google
  static Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
  }
}

/// HTTP client for authenticated requests
class Client extends BaseClient {
  final _inner = HttpClient();

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    final ioRequest = await _inner.openUrl(request.method, request.url);
    request.headers.forEach((key, value) {
      ioRequest.headers.set(key, value);
    });

    final response = await ioRequest.close();
    return StreamedResponse(
      response.cast<List<int>>(),
      response.statusCode,
      contentLength: response.contentLength,
      reasonPhrase: response.reasonPhrase,
      headers: response.headers.map((key, values) => MapEntry(key, values.join(', '))),
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      request: request,
    );
  }

  @override
  void close() {
    _inner.close();
  }
}
