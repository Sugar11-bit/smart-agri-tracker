
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class FarmingLogPhotoStorage {
  static const _uuid = Uuid();

  Future<Directory> _photoDirectory() async {
    final root = await getApplicationDocumentsDirectory();

    final directory = Directory(
      p.join(root.path, 'farming_log_photos'),
    );

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  Future<String> savePhoto(XFile source) async {
    final directory = await _photoDirectory();

    // imageQuality trong Camera là gợi ý,
    // không đảm bảo mọi ảnh đều thành JPEG.
    final extension = p.extension(source.path)
        .toLowerCase();

    const allowed = {
      '.jpg',
      '.jpeg',
      '.png',
      '.heic',
      '.heif',
      '.webp',
    };

    if (!allowed.contains(extension)) {
      throw const FileSystemException(
        'Định dạng ảnh chưa được hỗ trợ',
      );
    }

    final filename = '${_uuid.v4()}$extension';

    final destination = p.join(
      directory.path,
      filename,
    );

    final saved = await File(source.path).copy(
      destination,
    );

    if (!await saved.exists() ||
        await saved.length() == 0) {
      throw FileSystemException(
        'Sao chép ảnh thất bại',
        destination,
      );
    }

    return saved.path;
  }

  Future<void> deletePhoto(String path) async {
    final directory = await _photoDirectory();

    final normalizedPath = p.normalize(
      p.absolute(path),
    );

    final rootPath = p.normalize(
      p.absolute(directory.path),
    );

    // Chỉ cho phép xóa file nằm trong
    // thư mục ảnh do ứng dụng quản lý.
    if (!p.isWithin(rootPath, normalizedPath)) {
      throw ArgumentError(
        'Đường dẫn không thuộc thư mục ảnh',
      );
    }

    final file = File(normalizedPath);

    if (await file.exists()) {
      await file.delete();
    }
  }
}
