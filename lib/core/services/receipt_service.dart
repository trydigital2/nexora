import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'supabase_service.dart';

class ReceiptService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickReceiptImage({required ImageSource source}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      if (!SupabaseService.isDemoMode && SupabaseService.client != null) {
        final client = SupabaseService.client!;
        final user = client.auth.currentUser;
        if (user != null) {
          final fileExt = pickedFile.name.split('.').last;
          final fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExt';
          final bytes = await pickedFile.readAsBytes();

          await client.storage.from('receipts').uploadBinary(
                fileName,
                bytes,
              );

          final publicUrl = client.storage.from('receipts').getPublicUrl(fileName);
          return publicUrl;
        }
      }

      // Local / Offline fallback: return local path
      return pickedFile.path;
    } catch (e) {
      debugPrint('Error picking receipt image: $e');
      return null;
    }
  }

  Future<String?> pickProfileImage() async {
    return pickReceiptImage(source: ImageSource.gallery);
  }
}
