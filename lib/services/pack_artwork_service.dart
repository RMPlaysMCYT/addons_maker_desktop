import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

class PackArtworkService {
  const PackArtworkService();

  static String _iconDirectory(String projectPath) {
    return p.join(projectPath, 'marketing', 'icons');
  }

  Future<Uint8List> preparePNG(String sourcePath) async {
    final bytes = await File(sourcePath).readAsBytes();
    if (bytes.length > 15 * 1024 * 1024) {
      throw const FormatException('Selecte Image is too large!');
    }
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('Cannot Decode Images');
    }
    final oriented = img.bakeOrientation(decoded);
    final converted = img.copyResizeCropSquare(
      oriented,
      size: 256,
      interpolation: img.Interpolation.linear,
    );
    return Uint8List.fromList(img.encodePng(converted));
  }

  Future<void> saveProjectArtwork({
    required String projectPath,
    required Uint8List packIconPng,
    Uint8List? bugPackIconPng,
  }) async {
    final directory = Directory(_iconDirectory(projectPath));
    await directory.create(recursive: true);

    await File(p.join(directory.path, 'pack_icon.png'))
        .writeAsBytes(packIconPng, flush: true);

    if (bugPackIconPng != null) {
      await File(p.join(directory.path, 'pack_icon.png'))
          .writeAsBytes(packIconPng, flush: true);
    }
  }

  Future<void> copyToPacks({
    required String projectPath,
    required String bpPath,
    required String rpPath,
    bool copyBugIcontoBP = true,
  }) async {
    final sourceDirectory = _iconDirectory(projectPath);
    final mainIcon = File(p.join(sourceDirectory, 'pack_icon.png'));
    final bugIcon = File(p.join(sourceDirectory, 'pack_icon.png'));

    if(!await mainIcon.exists()){
      throw const FileSystemException(
        'No Project pack_icon was found'
      );
    }
  }
}
