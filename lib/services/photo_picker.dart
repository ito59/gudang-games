import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// A photo the member chose, already read into memory.
///
/// Bytes rather than a path: reading the file is the picker's job, so the
/// upload is pure network and nothing above this seam touches the disk.
class PickedPhoto {
  const PickedPhoto({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}

/// Picking a photo, behind a seam.
///
/// The plugin needs a real gallery and a platform channel, so tests inject
/// their own — the same arrangement [GoogleAuthenticator] uses.
abstract class PhotoPicker {
  /// Null when the member backed out of the picker.
  Future<PickedPhoto?> pick();
}

class GalleryPhotoPicker implements PhotoPicker {
  GalleryPhotoPicker({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<PickedPhoto?> pick() async {
    // Asked for at avatar size rather than full resolution: an 8 MB camera
    // photo is a slow upload for a picture shown at 98 pixels.
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null) return null;

    return PickedPhoto(bytes: await file.readAsBytes(), filename: file.name);
  }
}
