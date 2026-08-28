import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  /// Picks an image from gallery (web-safe: returns bytes + filename).
  /// Returns null if the user cancels.
  Future<(Uint8List bytes, String name)?> pickImage() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return (bytes, file.name);
  }

  /// Uploads [bytes] to Firebase Storage at [path] and returns the
  /// public download URL.
  Future<String> uploadBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final ref = _storage.ref(path);
    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );
    return await task.ref.getDownloadURL();
  }

  /// Convenience: pick from gallery then upload to [storagePath].
  /// Returns the download URL, or null if cancelled.
  Future<String?> pickAndUpload({required String storagePath}) async {
    final picked = await pickImage();
    if (picked == null) return null;
    final (bytes, name) = picked;
    final ext = name.contains('.') ? name.split('.').last : 'jpg';
    return uploadBytes(
      path: '$storagePath.$ext',
      bytes: bytes,
      contentType: 'image/$ext',
    );
  }
}
