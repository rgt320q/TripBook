import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;

class ImageStorageUtils {
  static const String _profileImagesDir = 'profile_images';
  
  /// Uygulama belgeler dizinini al
  static Future<Directory> get _appDocumentsDirectory async {
    return await getApplicationDocumentsDirectory();
  }
  
  /// Profil resimleri dizinini al veya oluştur
  static Future<Directory> get _profileImagesDirectory async {
    final appDir = await _appDocumentsDirectory;
    final profileDir = Directory(path.join(appDir.path, _profileImagesDir));
    
    if (!await profileDir.exists()) {
      await profileDir.create(recursive: true);
    }
    
    return profileDir;
  }
  
  /// Profil resmini kaydet ve dosya yolunu döndür
  static Future<String?> saveProfileImage(File imageFile, String userId) async {
    try {
      // Önce eski dosyayı sil (varsa)
      await deleteProfileImage(userId);
      
      // Resmi yeniden boyutlandır ve optimize et
      final Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(imageBytes);
      
      if (originalImage == null) {
        throw Exception('Resim formatı desteklenmiyor');
      }
      
      // Resmi 200x200 piksel olarak boyutlandır (profil için yeterli)
      img.Image resizedImage = img.copyResize(originalImage, width: 200, height: 200);
      final Uint8List optimizedBytes = Uint8List.fromList(
        img.encodeJpg(resizedImage, quality: 85)
      );
      
      // Dosya boyutu kontrolü (1MB limit)
      if (optimizedBytes.length > 1 * 1024 * 1024) {
        throw Exception('Optimize edilmiş resim çok büyük');
      }
      
      // Dosyayı kaydet
      final profileDir = await _profileImagesDirectory;
      final fileName = '$userId.jpg';
      final savedFile = File(path.join(profileDir.path, fileName));
      
      await savedFile.writeAsBytes(optimizedBytes);
      
      // Dosyanın gerçekten kaydedildiğinden emin ol
      if (await savedFile.exists()) {
        return savedFile.path;
      } else {
        throw Exception('Dosya kaydedilemedi');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Image storage error: $e');
      }
      return null;
    }
  }
  
  /// Profil resmini al
  static Future<File?> getProfileImage(String userId) async {
    try {
      final profileDir = await _profileImagesDirectory;
      final fileName = '$userId.jpg';
      final imageFile = File(path.join(profileDir.path, fileName));
      
      if (await imageFile.exists()) {
        return imageFile;
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Image load error: $e');
      }
      return null;
    }
  }
  
  /// Profil resmini sil
  static Future<bool> deleteProfileImage(String userId) async {
    try {
      final profileDir = await _profileImagesDirectory;
      final fileName = '$userId.jpg';
      final imageFile = File(path.join(profileDir.path, fileName));
      
      if (await imageFile.exists()) {
        await imageFile.delete();
        return true;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Image delete error: $e');
      }
      return false;
    }
  }
  
  /// Profil resmi var mı kontrol et
  static Future<bool> hasProfileImage(String userId) async {
    try {
      final profileDir = await _profileImagesDirectory;
      final fileName = '$userId.jpg';
      final imageFile = File(path.join(profileDir.path, fileName));
      
      return await imageFile.exists();
    } catch (e) {
      if (kDebugMode) {
        print('Image check error: $e');
      }
      return false;
    }
  }
  
  /// Tüm profil resimlerinin toplam boyutunu al (MB cinsinden)
  static Future<double> getTotalImageSize() async {
    try {
      final profileDir = await _profileImagesDirectory;
      
      if (!await profileDir.exists()) {
        return 0.0;
      }
      
      final files = await profileDir.list().toList();
      int totalBytes = 0;
      
      for (final file in files) {
        if (file is File && file.path.endsWith('.jpg')) {
          final stat = await file.stat();
          totalBytes += stat.size;
        }
      }
      
      return totalBytes / (1024 * 1024); // MB cinsinden döndür
    } catch (e) {
      if (kDebugMode) {
        print('Size calculation error: $e');
      }
      return 0.0;
    }
  }
  
  /// Eski profil resimlerini temizle (örneğin artık kullanılmayan kullanıcıların)
  static Future<void> cleanupOldImages(List<String> activeUserIds) async {
    try {
      final profileDir = await _profileImagesDirectory;
      
      if (!await profileDir.exists()) {
        return;
      }
      
      final files = await profileDir.list().toList();
      
      for (final file in files) {
        if (file is File && file.path.endsWith('.jpg')) {
          final fileName = path.basenameWithoutExtension(file.path);
          
          // Aktif kullanıcı listesinde yoksa sil
          if (!activeUserIds.contains(fileName)) {
            await file.delete();
            if (kDebugMode) {
              print('Old profile image deleted: $fileName');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Cleanup error: $e');
      }
    }
  }
}