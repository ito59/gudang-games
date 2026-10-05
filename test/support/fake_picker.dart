import 'package:bandar_games/services/photo_picker.dart';

/// A [PhotoPicker] that answers without a gallery.
class FakePhotoPicker implements PhotoPicker {
  FakePhotoPicker({this.photo});

  /// Null stands for the member backing out of the picker.
  PickedPhoto? photo;

  var pickCount = 0;

  @override
  Future<PickedPhoto?> pick() async {
    pickCount++;
    return photo;
  }
}
