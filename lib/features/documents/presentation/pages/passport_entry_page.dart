import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/presentation/widgets/generic_app_bar.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_capture_source.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_type.dart';
import 'package:pass_doc_manager/domain/documents/usecases/create_scanned_document.dart';
import 'package:pass_doc_manager/features/documents/presentation/services/document_ocr_parser.dart';
import 'package:pass_doc_manager/app/presentation/widgets/adaptive_modal.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class PassportEntryPage extends StatefulWidget {
  const PassportEntryPage({
    super.key,
    this.autoStartScan = false,
    CreateScannedDocument? createScannedDocument,
  }) : _createScannedDocument = createScannedDocument;

  final bool autoStartScan;
  final CreateScannedDocument? _createScannedDocument;

  @override
  State<PassportEntryPage> createState() => _PassportEntryPageState();
}

class _PassportEntryPageState extends State<PassportEntryPage> {
  final _ocrParser = const DocumentOcrParser();
  final ImagePicker _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _passportNumberController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _issuingCountryController = TextEditingController();

  bool _isSaving = false;
  bool _isScanning = false;
  bool _showReview = false;
  bool _showExtractionFailed = true;
  int _scannedPagesCount = 1;
  String _scanStatus = '';
  String? _scannedPreviewPath;
  DocumentCaptureSource _captureSource = DocumentCaptureSource.gallery;

  CreateScannedDocument get _createUseCase =>
      widget._createScannedDocument ?? getIt();

  @override
  void initState() {
    super.initState();
    _scanStatus = context.l10n.passportScanStatusIdle;
    _nationalityController.text = 'United Kingdom';
    _issuingCountryController.text = 'United Kingdom';
    if (widget.autoStartScan) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _retryScan();
        }
      });
    }
  }

  @override
  void dispose() {
    _passportNumberController.dispose();
    _fullNameController.dispose();
    _nationalityController.dispose();
    _birthDateController.dispose();
    _expiryDateController.dispose();
    _issuingCountryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appPalette.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Form(
                  key: _formKey,
                  child: _showReview ? _reviewScreen() : _addPassportScreen(),
                ),
              ),
            ),
            if (_isScanning || _isSaving)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.16),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _addPassportScreen() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        _previewPlaceholder(height: 186),
        if (_showExtractionFailed) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_rounded,
                color: Color(0xFFEF4444),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.passportExtractionFailed,
                style: const TextStyle(
                  fontSize: 34 / 1.4,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            context.l10n.passportExtractionFailedDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: context.appPalette.textSecondary,
              height: 1.36,
            ),
          ),
          SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _isScanning ? null : _retryScan,
            icon: Icon(Icons.refresh_rounded),
            label: Text(
              context.l10n.passportRetryScan,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE6ECFA),
              foregroundColor: context.appPalette.primary,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
        SizedBox(height: 8),
        Text(
          _scanStatus,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: context.appPalette.textSecondary,
          ),
        ),
        SizedBox(height: 18),
        Row(
          children: [
            Icon(
              Icons.edit_note_rounded,
              color: context.appPalette.primary,
              size: 22,
            ),
            SizedBox(width: 8),
            Text(
              context.l10n.passportDetailsTitle,
              style: TextStyle(
                fontSize: 35 / 1.5,
                fontWeight: FontWeight.w700,
                color: context.appPalette.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        _passportFormCard(saveLabel: context.l10n.passportSaveToVault),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield_moon_outlined,
              size: 16,
              color: context.appPalette.textMuted,
            ),
            SizedBox(width: 8),
            Text(
              context.l10n.passportEncryptedStorage,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: context.appPalette.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _reviewScreen() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        _reviewPreviewCard(),
        SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.documentStructuredInformation,
                style: TextStyle(
                  fontSize: 41 / 1.4,
                  fontWeight: FontWeight.w700,
                  color: context.appPalette.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F8EC),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    size: 16,
                    color: Color(0xFF0A8F57),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.l10n.passportAiVerified,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0A8F57),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _verifiedInfoCard(
          icon: Icons.badge_rounded,
          label: context.l10n.idEntryPassportNumber,
          value: _passportNumberController.text,
        ),
        const SizedBox(height: 10),
        _verifiedInfoCard(
          icon: Icons.person_rounded,
          label: context.l10n.idEntryFullName,
          value: _fullNameController.text,
        ),
        const SizedBox(height: 10),
        _verifiedInfoCard(
          icon: Icons.public_rounded,
          label: context.l10n.idEntryNationality,
          value: _nationalityController.text,
        ),
        const SizedBox(height: 10),
        _verifiedInfoCard(
          icon: Icons.cake_rounded,
          label: context.l10n.idEntryDateOfBirth,
          value: _birthDateController.text,
        ),
        const SizedBox(height: 10),
        _verifiedInfoCard(
          icon: Icons.calendar_month_rounded,
          label: context.l10n.idEntryExpiryDate,
          value: _expiryDateController.text,
        ),
        SizedBox(height: 10),
        _issuingCountryCard(),
        SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: Icon(Icons.lock_rounded),
          label: Text(
            context.l10n.passportSaveToSecureVault,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: context.appPalette.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          _scanStatus,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: context.appPalette.textSecondary,
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final title = _showReview
        ? context.l10n.passportReviewTitle
        : context.l10n.passportAddTitle;

    return GenericAppBar(
      backgroundColor: context.appPalette.background,
      onBackPressed: _isSaving ? null : () => Navigator.of(context).maybePop(),
      backIcon: Icons.arrow_back_ios_new_rounded,
      iconColor: context.appPalette.textPrimary,
      iconBackgroundColor: context.appPalette.surfaceSoft,
      title: title,
      titleColor: context.appPalette.textPrimary,
      titleStyle: TextStyle(
        fontSize: 20.5,
        fontWeight: FontWeight.w700,
        color: context.appPalette.textPrimary,
      ),
      actions: const [],
    );
  }

  Widget _previewPlaceholder({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: context.appPalette.surfaceSoft,
        border: Border.all(color: context.appPalette.stroke),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.description_outlined,
        size: 54,
        color: context.appPalette.textMuted,
      ),
    );
  }

  Widget _reviewPreviewCard() {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: context.appPalette.stroke),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: _previewImage(),
            ),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.zoom_in_rounded,
                    size: 18,
                    color: context.appPalette.primary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    context.l10n.passportTapToEnlarge,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.appPalette.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewImage() {
    if (_scannedPreviewPath != null && !kIsWeb) {
      final file = File(_scannedPreviewPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          cacheWidth: 1200,
        );
      }
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFCED9E8), Color(0xFFE9EFF7), Color(0xFFB7C8DB)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.book_rounded, size: 62, color: Color(0xFF8EA2BF)),
      ),
    );
  }

  Widget _verifiedInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appPalette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appPalette.stroke),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: context.appPalette.surfaceSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: context.appPalette.primary, size: 28),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: context.appPalette.textSecondary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value.trim().isEmpty ? '-' : value,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: context.appPalette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF10B981),
            size: 30,
          ),
        ],
      ),
    );
  }

  Widget _issuingCountryCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: context.appPalette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFA7C2FF),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: context.appPalette.surfaceSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.place_rounded,
              color: context.appPalette.primary,
              size: 28,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _issuingCountryController,
              validator: _requiredValidator,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: context.appPalette.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                labelText: context.l10n.idEntryIssuingCountry.toUpperCase(),
                hintText: context.l10n.idEntryEnterCountryName,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: context.appPalette.primary,
                ),
                hintStyle: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: context.appPalette.textMuted,
                ),
              ),
            ),
          ),
          Icon(
            Icons.edit_note_rounded,
            color: context.appPalette.textMuted,
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _passportFormCard({
    required String saveLabel,
    bool showDocumentTypeField = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDocumentTypeField) ...[
          Text(
            context.l10n.idEntryDocumentType,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: context.appPalette.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.appPalette.stroke),
              color: context.appPalette.surface,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.idEntryPassport,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: context.appPalette.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: context.appPalette.textMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        _label(context.l10n.idEntryPassportNumber.toUpperCase()),
        _field(
          controller: _passportNumberController,
          hint: context.l10n.idEntryEnterPassportNumber,
          validator: _requiredValidator,
        ),
        const SizedBox(height: 12),
        _label(context.l10n.idEntryFullNameAsPassport.toUpperCase()),
        _field(
          controller: _fullNameController,
          hint: context.l10n.idEntryEnterFullName,
          validator: _requiredValidator,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label(context.l10n.idEntryNationality.toUpperCase()),
                  _field(
                    controller: _nationalityController,
                    hint: context.l10n.idEntryCountryExample,
                    validator: _requiredValidator,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label(context.l10n.idEntryDateOfBirth.toUpperCase()),
                  _field(
                    controller: _birthDateController,
                    hint: context.l10n.idEntryDateFormatShort,
                    suffixIcon: Icons.calendar_month_outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label(context.l10n.idEntryExpiryDate.toUpperCase()),
                  _field(
                    controller: _expiryDateController,
                    hint: context.l10n.idEntryDateFormatShort,
                    suffixIcon: Icons.calendar_month_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label(context.l10n.idEntryIssuingCountry.toUpperCase()),
                  _field(
                    controller: _issuingCountryController,
                    hint: context.l10n.idEntryEnterCountry,
                    validator: _requiredValidator,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: Icon(Icons.lock_rounded),
          label: Text(
            saveLabel,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: context.appPalette.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: context.appPalette.textSecondary,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    IconData? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: context.appPalette.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: suffixIcon == null
            ? null
            : Icon(
                suffixIcon,
                color: context.appPalette.textSecondary,
                size: 20,
              ),
        filled: true,
        fillColor: context.appPalette.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: context.appPalette.stroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: context.appPalette.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: context.appPalette.primary, width: 1.2),
        ),
      ),
    );
  }

  Future<void> _retryScan() async {
    if (!_scannerSupported || _isScanning) {
      if (!_scannerSupported) {
        _showSnack(context.l10n.passportScannerMobileOnly);
      }
      return;
    }

    setState(() {
      _isScanning = true;
      _scanStatus = context.l10n.passportScanStatusScanning;
    });

    TextRecognizer? recognizer;
    try {
      final pickedFiles = await _pickScanImages();
      if (pickedFiles.isEmpty) {
        setState(() {
          _showExtractionFailed = true;
          _scanStatus = context.l10n.passportScanStatusCancelled;
        });
        return;
      }

      _captureSource = DocumentCaptureSource.camera;
      _scannedPagesCount = pickedFiles.length;
      _scannedPreviewPath = pickedFiles.first.path;

      recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final buffer = StringBuffer();
      for (final file in pickedFiles.take(5)) {
        final result = await recognizer.processImage(
          InputImage.fromFilePath(file.path),
        );
        if (result.text.trim().isNotEmpty) {
          buffer.writeln(result.text);
        }
      }

      final rawText = buffer.toString().trim();
      if (rawText.isEmpty) {
        setState(() {
          _showExtractionFailed = true;
          _scanStatus = context.l10n.passportScanStatusNoText;
        });
        _showSnack(context.l10n.idEntryNoReadableTextDetected);
        return;
      }

      final suggestion = _ocrParser.parse(
        type: DocumentType.passport,
        recognizedText: rawText,
      );
      _applySuggestion(suggestion);

      final mismatch = !_isDetectedTypeCompatible(suggestion.detectedIdType);
      final confidence = (suggestion.confidence * 100).round();
      final hasData =
          _passportNumberController.text.trim().isNotEmpty ||
          _fullNameController.text.trim().isNotEmpty;

      setState(() {
        _showExtractionFailed = !hasData;
        _showReview = hasData;
        _scanStatus = mismatch
            ? context.l10n.passportDetectedTypeStatus(
                confidence,
                suggestion.detectedIdType.label,
              )
            : context.l10n.passportDetectedStatus(confidence);
      });

      if (mismatch) {
        _showSnack(
          context.l10n.passportDetectedTypeVerify(
            suggestion.detectedIdType.label,
          ),
        );
      } else {
        _showSnack(context.l10n.passportDetailsExtracted);
      }
    } on PlatformException catch (error) {
      setState(() {
        _showExtractionFailed = true;
        _scanStatus = context.l10n.passportScanStatusFailed;
      });
      _showSnack(_scannerErrorMessage(error));
    } catch (_) {
      setState(() {
        _showExtractionFailed = true;
        _scanStatus = context.l10n.passportScanStatusFailed;
      });
      _showSnack(context.l10n.passportUnableScan);
    } finally {
      await recognizer?.close();
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<List<XFile>> _pickScanImages() async {
    final source = await _selectSource();
    if (source == null) {
      return const <XFile>[];
    }

    if (source == ImageSource.camera) {
      final file = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 92,
      );
      if (file == null) {
        return const <XFile>[];
      }
      return <XFile>[file];
    }

    final files = await _imagePicker.pickMultiImage(imageQuality: 92);
    return files;
  }

  Future<ImageSource?> _selectSource() async {
    if (!mounted) {
      return null;
    }
    return showAdaptiveModal<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(context.l10n.profileTakePhoto),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(context.l10n.profileChooseFromLibrary),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _applySuggestion(DocumentAutoFillSuggestion suggestion) {
    if (suggestion.identifierValue.trim().isNotEmpty) {
      _passportNumberController.text = suggestion.identifierValue;
    }
    if (suggestion.birthDate != null) {
      _birthDateController.text = DateFormat(
        'dd MMM yyyy',
      ).format(suggestion.birthDate!);
    }
    if (suggestion.expiryDate != null) {
      _expiryDateController.text = DateFormat(
        'dd MMM yyyy',
      ).format(suggestion.expiryDate!);
    }

    final fieldsByLabel = {
      for (final field in suggestion.structuredFields)
        (field['label'] ?? '').toLowerCase(): field['value'] ?? '',
    };

    final fullName = fieldsByLabel['full name'];
    if ((fullName ?? '').trim().isNotEmpty) {
      _fullNameController.text = fullName!;
    }

    final nationality =
        fieldsByLabel['nationality'] ??
        fieldsByLabel['country'] ??
        fieldsByLabel['issuing country'];
    if ((nationality ?? '').trim().isNotEmpty) {
      _nationalityController.text = nationality!;
    }

    final birthDate = fieldsByLabel['birth date'];
    if ((birthDate ?? '').trim().isNotEmpty &&
        _birthDateController.text.trim().isEmpty) {
      _birthDateController.text = birthDate!;
    }

    final expiryDate = fieldsByLabel['expiry date'];
    if ((expiryDate ?? '').trim().isNotEmpty &&
        _expiryDateController.text.trim().isEmpty) {
      _expiryDateController.text = expiryDate!;
    }

    final issuing = fieldsByLabel['issuing country'] ?? suggestion.issuer;
    if (issuing.trim().isNotEmpty) {
      _issuingCountryController.text = issuing;
    }
  }

  bool _isDetectedTypeCompatible(ScannedIdType type) {
    return type == ScannedIdType.passport || type == ScannedIdType.unknown;
  }

  bool get _scannerSupported {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final created = await _createUseCase(
        CreateScannedDocumentParams(
          type: DocumentType.passport,
          source: _captureSource,
          scanPagesCount: _scannedPagesCount,
          issuerOverride: _issuingCountryController.text.trim(),
          identifierLabelOverride: 'Passport Number',
          identifierValueOverride: _passportNumberController.text.trim(),
          expiryDateOverride: DocumentOcrParser.parseLooseDate(
            _expiryDateController.text,
          ),
          structuredFieldsOverride: [
            {
              'label': 'Passport Number',
              'value': _passportNumberController.text.trim(),
            },
            {'label': 'Full Name', 'value': _fullNameController.text.trim()},
            {
              'label': 'Nationality',
              'value': _nationalityController.text.trim(),
            },
            {'label': 'Birth Date', 'value': _birthDateController.text.trim()},
            {
              'label': 'Expiry Date',
              'value': _expiryDateController.text.trim(),
            },
            {
              'label': 'Issuing Country',
              'value': _issuingCountryController.text.trim(),
            },
          ],
          tagsOverride: const ['Travel', 'ID', 'Personal'],
        ),
      );
      if (!mounted) {
        return;
      }
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.of(context).pop(created.id);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnack(context.l10n.passportUnableSave);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String? _requiredValidator(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return context.l10n.idEntryRequired;
    }
    return null;
  }

  String _scannerErrorMessage(PlatformException error) {
    if (error.code == 'UNAVAILABLE') {
      return context.l10n.passportScannerUnavailableDevice;
    }
    final message = error.message?.trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }
    return context.l10n.passportUnableScan;
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
