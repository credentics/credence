import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pass_doc_manager/app/presentation/widgets/generic_app_bar.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/core/utils/local_file_image_provider.dart';
import 'package:pass_doc_manager/app/presentation/widgets/adaptive_modal.dart';
import 'package:pass_doc_manager/domain/profile/entities/profile_entity.dart';
import 'package:pass_doc_manager/domain/profile/usecases/save_profile.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    required this.initialProfile,
    required this.saveProfile,
  });

  final ProfileEntity initialProfile;
  final SaveProfile saveProfile;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  final ImagePicker _imagePicker = ImagePicker();

  String _photoPath = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.initialProfile.firstName,
    );
    _lastNameController = TextEditingController(
      text: widget.initialProfile.lastName,
    );
    _emailController = TextEditingController(text: widget.initialProfile.email);
    _phoneController = TextEditingController(text: widget.initialProfile.phone);
    _photoPath = widget.initialProfile.photoPath;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final imageProvider = resolveLocalFileImageProvider(_photoPath);

    return Scaffold(
      backgroundColor: context.appPalette.background,
      appBar: GenericAppBar(
        backgroundColor: context.appPalette.background,
        onBackPressed: () => Navigator.of(context).pop(false),
        backIcon: Icons.close_rounded,
        title: l10n.profileEditTitle,
        titleStyle: TextStyle(
          fontWeight: FontWeight.w700,
          color: context.appPalette.textPrimary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              l10n.commonCancel,
              style: TextStyle(
                color: Color(0xFF0C5DE8),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        showDivider: false,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickPhoto,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 150,
                              height: 150,
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: context.appPalette.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: context.appPalette.surfaceSoft,
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: imageProvider == null
                                    ? Container(
                                        color: context.appPalette.primarySoft,
                                        alignment: Alignment.center,
                                        child: Text(
                                          _initials(),
                                          style: TextStyle(
                                            fontSize: 38,
                                            fontWeight: FontWeight.w700,
                                            color: context.appPalette.primary,
                                          ),
                                        ),
                                      )
                                    : Image(
                                        image: imageProvider,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            Positioned(
                              right: -4,
                              bottom: 6,
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: context.appPalette.primary,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x220A0D18),
                                      blurRadius: 10,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 18),
                    Text(
                      l10n.profileUpdatePhoto,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: context.appPalette.textPrimary,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      l10n.profileTapChangePhoto,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: context.appPalette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _InputField(
                      label: l10n.profileFirstName,
                      controller: _firstNameController,
                    ),
                    const SizedBox(height: 16),
                    _InputField(
                      label: l10n.profileLastName,
                      controller: _lastNameController,
                    ),
                    const SizedBox(height: 16),
                    _InputField(
                      label: l10n.profileEmailAddress,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _InputField(
                      label: l10n.profileSecurePhone,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.shield_outlined,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.appPalette.surfaceSoft,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.appPalette.stroke),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_rounded,
                            size: 22,
                            color: context.appPalette.primary,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.profileContactInfoSecurityNotice,
                              style: TextStyle(
                                color: context.appPalette.textSecondary,
                                fontSize: 13,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
                child: SizedBox(
                  height: 58,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: context.appPalette.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(
                      _isSaving ? l10n.commonSaving : l10n.profileSaveChanges,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
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

  String _initials() {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final f = first.isEmpty ? '' : first.substring(0, 1);
    final l = last.isEmpty ? '' : last.substring(0, 1);
    final value = (f + l).trim();
    return value.isEmpty ? 'V' : value.toUpperCase();
  }

  Future<void> _pickPhoto() async {
    final source = await showAdaptiveModal<ImageSource>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text(context.l10n.profileChooseFromLibrary),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: Text(context.l10n.profileTakePhoto),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(ImageSource.camera),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 92,
      maxWidth: 2000,
    );
    if (image == null) {
      return;
    }

    setState(() {
      _photoPath = image.path;
    });
  }

  Future<void> _save() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.profileRequiredFieldsMessage)),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final payload = widget.initialProfile.copyWith(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: _phoneController.text.trim(),
        photoPath: _photoPath,
        updatedAt: DateTime.now(),
      );

      await widget.saveProfile(SaveProfileParams(profile: payload));
      if (!mounted) {
        return;
      }
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.profileUnableSave)));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.prefixIcon,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF273A59),
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            color: context.appPalette.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon, color: const Color(0xFF95A6BF)),
            filled: true,
            fillColor: context.appPalette.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: context.appPalette.stroke),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: context.appPalette.stroke),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: context.appPalette.primary),
            ),
          ),
        ),
      ],
    );
  }
}
