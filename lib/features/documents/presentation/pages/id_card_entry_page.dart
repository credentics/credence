import 'dart:math';

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

class IdCardEntryPage extends StatefulWidget {
  const IdCardEntryPage({
    super.key,
    this.autoStartScan = false,
    CreateScannedDocument? createScannedDocument,
  }) : _createScannedDocument = createScannedDocument;

  final bool autoStartScan;
  final CreateScannedDocument? _createScannedDocument;

  @override
  State<IdCardEntryPage> createState() => _IdCardEntryPageState();
}

class _IdCardEntryPageState extends State<IdCardEntryPage> {
  final _ocrParser = const DocumentOcrParser();
  final ImagePicker _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _idNumberController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _authorityController = TextEditingController();

  bool _isSaving = false;
  bool _isScanning = false;
  bool _showReview = false;
  bool _frontUploaded = false;
  bool _backUploaded = false;
  int _scanFilesDetected = 0;
  String _scanStatusLabel = 'Waiting for ID scan';
  DocumentCaptureSource _captureSource = DocumentCaptureSource.gallery;

  CreateScannedDocument get _createUseCase =>
      widget._createScannedDocument ?? getIt();

  @override
  void initState() {
    super.initState();
    _nationalityController.text = 'United States';
    if (widget.autoStartScan) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scanSide(_IdScanSide.front, moveToReview: true);
        }
      });
    }
  }

  @override
  void dispose() {
    _idNumberController.dispose();
    _fullNameController.dispose();
    _nationalityController.dispose();
    _birthDateController.dispose();
    _expiryDateController.dispose();
    _authorityController.dispose();
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
                constraints: const BoxConstraints(maxWidth: 620),
                child: Form(
                  key: _formKey,
                  child: _showReview ? _reviewView() : _manualView(),
                ),
              ),
            ),
            if (_isSaving || _isScanning)
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

  Widget _manualView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        Text(
          'ID Documents',
          style: TextStyle(
            fontSize: 38 / 1.4,
            fontWeight: FontWeight.w700,
            color: context.appPalette.textPrimary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Please upload high-quality photos of your identity document.',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: context.appPalette.textSecondary,
            height: 1.32,
          ),
        ),
        const SizedBox(height: 18),
        _scanSideCard(
          title: context.l10n.idCardFrontSide,
          uploaded: _frontUploaded,
          onTap: () => _scanSide(_IdScanSide.front),
        ),
        SizedBox(height: 8),
        Text(
          'Upload Front Side',
          style: TextStyle(
            fontSize: 34 / 1.5,
            fontWeight: FontWeight.w700,
            color: context.appPalette.textPrimary,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Tap to capture or upload',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: context.appPalette.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        _scanSideCard(
          title: context.l10n.idCardBackSide,
          uploaded: _backUploaded,
          onTap: () => _scanSide(_IdScanSide.back),
        ),
        SizedBox(height: 8),
        Text(
          'Upload Back Side',
          style: TextStyle(
            fontSize: 34 / 1.5,
            fontWeight: FontWeight.w700,
            color: context.appPalette.textPrimary,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Tap to capture or upload',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: context.appPalette.textSecondary,
          ),
        ),
        SizedBox(height: 18),
        Row(
          children: [
            Icon(
              Icons.badge_outlined,
              color: context.appPalette.primary,
              size: 22,
            ),
            SizedBox(width: 8),
            Text(
              'ID Information',
              style: TextStyle(
                fontSize: 36 / 1.5,
                fontWeight: FontWeight.w700,
                color: context.appPalette.textPrimary,
              ),
            ),
          ],
        ),
        Divider(height: 18, color: context.appPalette.strokeStrong),
        _inputLabel('ID Number'),
        _inputField(
          controller: _idNumberController,
          hint: 'Enter identification number',
          validator: _requiredValidator,
        ),
        const SizedBox(height: 12),
        _inputLabel('Full Name'),
        _inputField(
          controller: _fullNameController,
          hint: 'As shown on document',
          validator: _requiredValidator,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _inputLabel('Nationality'),
                  _inputField(
                    controller: _nationalityController,
                    hint: 'Country',
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
                  _inputLabel('Expiry Date'),
                  _inputField(
                    controller: _expiryDateController,
                    hint: 'MM/YY',
                    suffixIcon: Icons.calendar_month_outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        _inputLabel('Issuing Authority'),
        _inputField(
          controller: _authorityController,
          hint: 'Department of State Services',
        ),
        SizedBox(height: 18),
        FilledButton(
          onPressed: _isSaving ? null : _verifyIdentity,
          style: FilledButton.styleFrom(
            backgroundColor: context.appPalette.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: const Text(
            'Verify Identity',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 16,
              color: Color(0xFF16A34A),
            ),
            SizedBox(width: 8),
            Text(
              'Secure 256-bit encrypted connection',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: context.appPalette.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _reviewView() {
    final filesLabel = _scanFilesDetected > 0
        ? '$_scanFilesDetected Files Detected'
        : 'Manual Entry';

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        Row(
          children: [
            Text(
              'ID Card Scans',
              style: TextStyle(
                fontSize: 38 / 1.4,
                fontWeight: FontWeight.w700,
                color: context.appPalette.textPrimary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFDCE9FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                filesLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.appPalette.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _scanPreviewCard(
                sideLabel: 'FRONT',
                uploaded: _frontUploaded,
                onTap: () => _scanSide(_IdScanSide.front, moveToReview: true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _scanPreviewCard(
                sideLabel: 'BACK',
                uploaded: _backUploaded,
                onTap: () => _scanSide(_IdScanSide.back, moveToReview: true),
              ),
            ),
          ],
        ),
        SizedBox(height: 18),
        Row(
          children: [
            Text(
              'Extracted Information',
              style: TextStyle(
                fontSize: 40 / 1.4,
                fontWeight: FontWeight.w700,
                color: context.appPalette.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _isScanning
                  ? null
                  : () => _scanSide(_IdScanSide.front, moveToReview: true),
              icon: Icon(Icons.refresh_rounded, size: 18),
              label: Text(context.l10n.idCardRescan),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.appPalette.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.appPalette.stroke),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _reviewField(
                label: 'Full Name',
                controller: _fullNameController,
                hint: 'Full name',
                validator: _requiredValidator,
              ),
              const SizedBox(height: 10),
              _reviewField(
                label: 'ID Number',
                controller: _idNumberController,
                hint: 'A-9832-114-098',
                validator: _requiredValidator,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _reviewField(
                      label: 'Date of Birth',
                      controller: _birthDateController,
                      hint: 'dd/MM/yyyy',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _reviewField(
                      label: 'Expiry Date',
                      controller: _expiryDateController,
                      hint: 'dd/MM/yyyy',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _reviewField(
                label: 'Issuing Authority',
                controller: _authorityController,
                hint: 'Department of State Services',
              ),
              const SizedBox(height: 10),
              _reviewField(
                label: 'Nationality',
                controller: _nationalityController,
                hint: 'Country',
                validator: _requiredValidator,
              ),
            ],
          ),
        ),
        SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: Icon(Icons.verified_rounded),
          label: Text(
            'Confirm & Save ID',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: context.appPalette.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(58),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        SizedBox(height: 6),
        Text(
          _scanStatusLabel,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: context.appPalette.textSecondary,
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return GenericAppBar(
      backgroundColor: context.appPalette.background,
      onBackPressed: _isSaving
          ? null
          : () {
              if (_showReview) {
                setState(() {
                  _showReview = false;
                });
                return;
              }
              Navigator.of(context).maybePop();
            },
      backIcon: Icons.arrow_back_ios_new_rounded,
      title: _showReview ? 'Review ID Details' : 'Manual ID Entry',
      titleStyle: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        color: context.appPalette.textPrimary,
      ),
    );
  }

  Widget _scanSideCard({
    required String title,
    required bool uploaded,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isScanning ? null : onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        height: 152,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD8E1F2), width: 1.2),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EEFB),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Icon(
                  uploaded
                      ? Icons.check_circle_rounded
                      : Icons.add_a_photo_rounded,
                  color: uploaded
                      ? const Color(0xFF16A34A)
                      : context.appPalette.primary,
                  size: 26,
                ),
              ),
              SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 28 / 1.4,
                  fontWeight: FontWeight.w600,
                  color: uploaded
                      ? context.appPalette.textPrimary
                      : context.appPalette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scanPreviewCard({
    required String sideLabel,
    required bool uploaded,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isScanning ? null : onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        height: 124,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: context.appPalette.stroke),
          gradient: uploaded
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0A1328), Color(0xFF5CB0FF)],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE8EEF4), Color(0xFFD4DEE8)],
                ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 10,
              right: 10,
              top: 18,
              bottom: 24,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  color: uploaded
                      ? Colors.black.withValues(alpha: 0.22)
                      : Colors.white.withValues(alpha: 0.6),
                  child: Icon(
                    uploaded
                        ? Icons.badge_rounded
                        : Icons.image_not_supported_outlined,
                    size: 34,
                    color: uploaded
                        ? Colors.white
                        : context.appPalette.textMuted,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  sideLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: context.appPalette.textSecondary,
      ),
    );
  }

  Widget _inputField({
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
                size: 20,
                color: context.appPalette.textSecondary,
              ),
        filled: true,
        fillColor: context.appPalette.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
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

  Widget _reviewField({
    required String label,
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: context.appPalette.textSecondary,
          ),
        ),
        SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: context.appPalette.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: Icon(
              Icons.edit_rounded,
              size: 18,
              color: context.appPalette.textMuted,
            ),
            filled: true,
            fillColor: context.appPalette.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
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
              borderSide: BorderSide(
                color: context.appPalette.primary,
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String? _requiredValidator(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  void _verifyIdentity() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _showReview = true;
      _scanStatusLabel = _scanFilesDetected > 0
          ? 'Ready to confirm and save.'
          : 'Manual entry ready to save.';
    });
  }

  Future<void> _scanSide(_IdScanSide side, {bool moveToReview = false}) async {
    if (!_scannerSupported) {
      _showSnack('Scanner is currently supported on mobile devices only.');
      return;
    }
    if (_isScanning) {
      return;
    }

    setState(() {
      _isScanning = true;
      _scanStatusLabel = 'Scanning ${side.label.toLowerCase()}...';
    });

    TextRecognizer? recognizer;
    try {
      final pickedFiles = await _pickScanImages();
      if (pickedFiles.isEmpty) {
        setState(() {
          _scanStatusLabel = 'Scan cancelled';
        });
        return;
      }

      recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final textBuffer = StringBuffer();
      for (final file in pickedFiles.take(5)) {
        final inputImage = InputImage.fromFilePath(file.path);
        final result = await recognizer.processImage(inputImage);
        if (result.text.trim().isNotEmpty) {
          textBuffer.writeln(result.text);
        }
      }

      if (side == _IdScanSide.front) {
        _frontUploaded = true;
        if (pickedFiles.length > 1) {
          _backUploaded = true;
        }
      } else {
        _backUploaded = true;
      }

      _scanFilesDetected = (_frontUploaded ? 1 : 0) + (_backUploaded ? 1 : 0);
      _captureSource = DocumentCaptureSource.camera;

      final rawText = textBuffer.toString().trim();
      if (rawText.isNotEmpty) {
        final suggestion = _ocrParser.parse(
          type: DocumentType.idCard,
          recognizedText: rawText,
        );
        _applySuggestion(suggestion);
        final mismatch = !_isDetectedTypeCompatible(suggestion.detectedIdType);
        final confidence = (suggestion.confidence * 100).round();
        _scanStatusLabel = mismatch
            ? 'Detected ${suggestion.detectedIdType.label} ($confidence%) • verify data'
            : 'Extraction complete ($confidence%)';
        if (mismatch) {
          _showSnack(
            'Detected ${suggestion.detectedIdType.label}. Please review fields before saving.',
          );
        } else {
          _showSnack('ID details extracted successfully.');
        }
      } else {
        _scanStatusLabel = 'No readable text detected';
        _showSnack('No readable text detected. Fill details manually.');
      }

      if (moveToReview || _frontUploaded) {
        setState(() {
          _showReview = true;
        });
      } else {
        setState(() {});
      }
    } on PlatformException catch (error) {
      _showSnack(_scannerErrorMessage(error));
      setState(() {
        _scanStatusLabel = 'Scan failed';
      });
    } catch (_) {
      _showSnack('Unable to scan ID right now.');
      setState(() {
        _scanStatusLabel = 'Scan failed';
      });
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
                title: Text(context.l10n.commonTakePhoto),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(context.l10n.scanChooseFromLibrary),
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
      _idNumberController.text = suggestion.identifierValue;
    }
    if (suggestion.birthDate != null) {
      _birthDateController.text = DateFormat(
        'dd/MM/yyyy',
      ).format(suggestion.birthDate!);
    }
    if (suggestion.expiryDate != null) {
      _expiryDateController.text = DateFormat(
        'dd/MM/yyyy',
      ).format(suggestion.expiryDate!);
    }

    final fieldsByLabel = <String, String>{
      for (final field in suggestion.structuredFields)
        (field['label'] ?? '').toLowerCase(): (field['value'] ?? '').trim(),
    };

    final fullName = fieldsByLabel['full name'];
    if ((fullName ?? '').isNotEmpty) {
      _fullNameController.text = fullName!;
    }

    final nationality =
        fieldsByLabel['nationality'] ??
        fieldsByLabel['country'] ??
        fieldsByLabel['issuing country'];
    if ((nationality ?? '').isNotEmpty) {
      _nationalityController.text = nationality!;
    }

    final authority = fieldsByLabel['issuing authority'];
    if ((authority ?? '').isNotEmpty) {
      _authorityController.text = authority!;
    }

    final birthDate = fieldsByLabel['birth date'];
    if ((birthDate ?? '').isNotEmpty &&
        _birthDateController.text.trim().isEmpty) {
      _birthDateController.text = birthDate!;
    }

    final expiryDate = fieldsByLabel['expiry date'];
    if ((expiryDate ?? '').isNotEmpty &&
        _expiryDateController.text.trim().isEmpty) {
      _expiryDateController.text = expiryDate!;
    }
  }

  bool _isDetectedTypeCompatible(ScannedIdType detected) {
    return detected == ScannedIdType.idCard ||
        detected == ScannedIdType.residencePermit ||
        detected == ScannedIdType.studentId ||
        detected == ScannedIdType.disabilityCard ||
        detected == ScannedIdType.proofOfAgeCard;
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
      final parsedExpiry = DocumentOcrParser.parseLooseDate(
        _expiryDateController.text,
      );
      final structuredFields = _buildStructuredFields();
      final issuer = _authorityController.text.trim().isEmpty
          ? _nationalityController.text.trim()
          : _authorityController.text.trim();

      final created = await _createUseCase(
        CreateScannedDocumentParams(
          type: DocumentType.idCard,
          source: _captureSource,
          scanPagesCount: max(1, _scanFilesDetected),
          issuerOverride: issuer,
          identifierLabelOverride: 'ID Number',
          identifierValueOverride: _idNumberController.text.trim(),
          expiryDateOverride: parsedExpiry,
          structuredFieldsOverride: structuredFields,
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
      _showSnack('Unable to save ID document.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  List<Map<String, String>> _buildStructuredFields() {
    final fields = <Map<String, String>>[];

    void add(String label, String value) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        fields.add({'label': label, 'value': trimmed});
      }
    }

    add('ID Number', _idNumberController.text);
    add('Full Name', _fullNameController.text);
    add('Nationality', _nationalityController.text);
    add('Birth Date', _birthDateController.text);
    add('Expiry Date', _expiryDateController.text);
    add('Issuing Authority', _authorityController.text);
    return fields;
  }

  String _scannerErrorMessage(PlatformException error) {
    if (error.code == 'UNAVAILABLE') {
      return 'Scanner unavailable on this device. Use a real iPhone/Android device.';
    }
    final message = error.message?.trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }
    return 'Unable to scan ID right now.';
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

enum _IdScanSide { front, back }

extension on _IdScanSide {
  String get label => switch (this) {
    _IdScanSide.front => 'Front Side',
    _IdScanSide.back => 'Back Side',
  };
}
