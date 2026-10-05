import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/user_profile.dart';
import '../services/photo_picker.dart';
import '../state/profile_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_panel.dart';
import '../widgets/gradient_button.dart';
import '../widgets/page_header.dart';
import '../widgets/profile_photo.dart';

/// Edits a copy of the profile and pops the result. The caller decides
/// whether to commit it, so backing out never mutates anything.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile, this.picker});

  final UserProfile profile;

  /// Injected by tests; the real gallery otherwise.
  final PhotoPicker? picker;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _bioLimit = 160;

  late final PhotoPicker _picker = widget.picker ?? GalleryPhotoPicker();

  /// Set while the upload is in flight, so the avatar says something is
  /// happening and a second tap cannot start another one.
  var _uploading = false;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _bio;
  late final TextEditingController _location;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.name);
    _username = TextEditingController(text: widget.profile.username);
    _bio = TextEditingController(text: widget.profile.bio);
    _location = TextEditingController(text: widget.profile.location);
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    _location.dispose();
    super.dispose();
  }

  UserProfile get _edited => widget.profile.copyWith(
    name: _name.text.trim(),
    username: _username.text.trim(),
    bio: _bio.text.trim(),
    location: _location.text.trim(),
  );

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_edited);
  }

  /// The photo is saved on its own, the moment it is chosen: it has its own
  /// endpoint and its own way to fail, and holding it behind Save would mean
  /// a discarded edit silently threw the upload away too.
  Future<void> _changePhoto() async {
    if (_uploading) return;

    final controller = ProfileScope.of(context);
    final remove = await _askWhat(hasPhoto: controller.profile.avatarUrl != null);
    if (remove == null || !mounted) return;

    if (!remove) {
      final photo = await _picker.pick();
      // Backing out of the gallery is an answer, not a failure.
      if (photo == null || !mounted) return;

      await _run(() => controller.setPhoto(photo), done: 'Photo updated.');
      return;
    }

    await _run(controller.removePhoto, done: 'Photo removed.');
  }

  Future<void> _run(
    Future<String?> Function() call, {
    required String done,
  }) async {
    setState(() => _uploading = true);
    final error = await call();
    if (!mounted) return;

    setState(() => _uploading = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error ?? done)));
  }

  /// True to remove, false to choose a new one, null to back out.
  ///
  /// With no photo yet there is nothing to remove, so the tap goes straight
  /// to the gallery rather than through a sheet with one useful row.
  Future<bool?> _askWhat({required bool hasPhoto}) {
    if (!hasPhoto) return Future.value(false);

    return showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(AppIcons.photoCamera, color: AppColors.primary),
              title: const Text('Choose a photo'),
              onTap: () => Navigator.of(context).pop(false),
            ),
            ListTile(
              leading: const Icon(AppIcons.close, color: AppColors.tertiary),
              title: const Text('Remove photo'),
              onTap: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDiscard() async {
    final navigator = Navigator.of(context);

    if (_edited == widget.profile) {
      navigator.pop();
      return;
    }

    final discard = await showDialog<bool>(
      context: context,
      // Colours and type come from AppTheme.dialogTheme.
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your edits will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.tertiary,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (discard ?? false) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return PopScope(
      // Route the system back gesture through the same discard check.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        body: Column(
          children: [
            PageHeader(
              title: 'Edit Profile',
              onBack: _confirmDiscard,
              trailing: IconButton(
                onPressed: _save,
                tooltip: 'Save',
                icon: const Icon(AppIcons.check, color: AppColors.primary),
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.only(
                    left: AppTheme.marginMobile,
                    right: AppTheme.marginMobile,
                    top: AppTheme.lg,
                    // Keep the last field clear of the keyboard.
                    bottom: AppTheme.xl + bottomInset,
                  ),
                  children: [
                    _AvatarPicker(
                      profile: ProfileScope.of(context).profile,
                      busy: _uploading,
                      onTap: _changePhoto,
                    ),
                    const SizedBox(height: AppTheme.xl),
                    _Field(
                      controller: _name,
                      label: 'Display name',
                      textCapitalization: TextCapitalization.words,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Display name cannot be empty'
                          : null,
                    ),
                    const SizedBox(height: AppTheme.md),
                    _Field(
                      controller: _username,
                      label: 'Username',
                      prefix: '@',
                      // Usernames are handles: no spaces, no punctuation.
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9_]'),
                        ),
                      ],
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return 'Username cannot be empty';
                        if (text.length < 3) {
                          return 'Use at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.md),
                    _Field(
                      controller: _bio,
                      label: 'Bio',
                      maxLines: 3,
                      maxLength: _bioLimit,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: AppTheme.md),
                    _Field(
                      controller: _location,
                      label: 'Location',
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: AppTheme.xl),
                    GradientButton(
                      icon: AppIcons.check,
                      label: 'Save changes',
                      expand: true,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.profile,
    required this.busy,
    required this.onTap,
  });

  final UserProfile profile;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 112,
        height: 112,
        child: Stack(
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              padding: const EdgeInsets.all(3),
              child: ClipOval(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ProfilePhoto(profile: profile),
                    if (busy)
                      const ColoredBox(
                        color: Color(0x99000000),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Material(
                color: AppColors.primaryContainer,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: busy ? null : onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Semantics(
                      button: true,
                      label: 'Change photo',
                      child: const Icon(
                        AppIcons.photoCamera,
                        size: 18,
                        color: AppColors.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.validator,
    this.prefix,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final String? prefix;
  final int maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      borderSide: const BorderSide(color: AppColors.outlineVariant),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppTheme.sm),
        GlassPanel(
          radius: AppTheme.radiusLg,
          child: TextFormField(
            controller: controller,
            validator: validator,
            maxLines: maxLines,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            textCapitalization: textCapitalization,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurface),
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              prefixText: prefix,
              prefixStyle: AppTextStyles.bodyMd.copyWith(
                color: AppColors.primary,
              ),
              counterStyle: AppTextStyles.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              filled: false,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.md,
                vertical: 14,
              ),
              border: border,
              enabledBorder: border,
              focusedBorder: border.copyBorderWith(
                const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              errorBorder: border.copyBorderWith(
                const BorderSide(color: AppColors.tertiary),
              ),
              focusedErrorBorder: border.copyBorderWith(
                const BorderSide(color: AppColors.tertiary, width: 1.5),
              ),
              errorStyle: AppTextStyles.labelSm.copyWith(
                color: AppColors.tertiary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

extension on OutlineInputBorder {
  OutlineInputBorder copyBorderWith(BorderSide side) =>
      OutlineInputBorder(borderRadius: borderRadius, borderSide: side);
}
