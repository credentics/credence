import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pass_doc_manager/app/presentation/widgets/generic_app_bar.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_type.dart';
import 'package:pass_doc_manager/app/presentation/widgets/adaptive_modal.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class DocumentScanFlowResult {
  const DocumentScanFlowResult({required this.pagesCount});

  final int pagesCount;
}

class DocumentScanFlowPage extends StatefulWidget {
  const DocumentScanFlowPage({
    super.key,
    required this.type,
    this.replaceMode = false,
  });

  final DocumentType type;
  final bool replaceMode;

  @override
  State<DocumentScanFlowPage> createState() => _DocumentScanFlowPageState();
}

class _DocumentScanFlowPageState extends State<DocumentScanFlowPage> {
  final ImagePicker _imagePicker = ImagePicker();
  int _capturedPages = 0;
  int _idStep = 1;
  bool _showFrontCapturedBanner = false;
  bool _flashEnabled = false;
  bool _isScanning = false;
  late bool _showCaptureSession;

  bool get _isPassport => widget.type == DocumentType.passport;
  bool get _isIdCard => widget.type == DocumentType.idCard;
  bool get _showGuide => !_showCaptureSession && (_isPassport || _isIdCard);

  @override
  void initState() {
    super.initState();
    _showCaptureSession = !(_isPassport || _isIdCard);
  }

  @override
  Widget build(BuildContext context) {
    if (_showGuide) {
      return _isPassport ? _passportGuide(context) : _idCardGuide(context);
    }
    return _captureSession(context);
  }

  Widget _passportGuide(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appPalette.background,
      appBar: GenericAppBar(
        backgroundColor: context.appPalette.background,
        onBackPressed: () => Navigator.of(context).maybePop(),
        backIcon: Icons.arrow_back_ios_new_rounded,
        title: context.l10n.scanPassportTitle,
        titleStyle: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: context.appPalette.textPrimary,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'PASSPORT PHOTO PAGE',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.8,
                        color: context.appPalette.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: context.appPalette.primarySoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '1 / 1',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.appPalette.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(999)),
                child: LinearProgressIndicator(
                  value: 1,
                  minHeight: 8,
                  backgroundColor: context.appPalette.stroke,
                  color: context.appPalette.primary,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 0),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF04070E), Color(0xFF0D1119)],
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 72),
                    Container(
                      height: 236,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: context.appPalette.primary, width: 4),
                        gradient: const RadialGradient(
                          center: Alignment.center,
                          radius: 1.2,
                          colors: [Color(0xAA1E293B), Color(0x55111827)],
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'ALIGN PAGE HERE',
                          style: TextStyle(
                            fontSize: 36 / 1.7,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 3.2,
                            color: Color(0xFF95A3B7),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Ready to scan',
                      style: TextStyle(
                        fontSize: 50 / 1.4,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 26),
                      child: Text(
                        "Position your passport's information page within the frame for automatic detection.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 34 / 1.8,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFBEC8D8),
                          height: 1.25,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ControlBubble(
                            icon: Icons.photo_library_outlined,
                            label: 'GALLERY',
                            onTap: () => _finish(pagesCount: 1),
                          ),
                          _MainCaptureButton(onTap: _capture),
                          _ControlBubble(
                            icon: _flashEnabled
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded,
                            label: 'FLASH',
                            onTap: () {
                              setState(() {
                                _flashEnabled = !_flashEnabled;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: context.appPalette.surfaceSoft,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: context.appPalette.stroke),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_rounded, color: context.appPalette.primary),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Make sure there is no glare on the surface',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: context.appPalette.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _idCardGuide(BuildContext context) {
    final progress = _idStep == 1 ? 0.5 : 1.0;
    final stepLabel = _idStep == 1 ? 'Step 1: Front Side' : 'Step 2: Back Side';
    final stepCount = _idStep == 1 ? '1 of 2' : '2 of 2';

    return Scaffold(
      backgroundColor: context.appPalette.background,
      appBar: GenericAppBar(
        backgroundColor: context.appPalette.background,
        onBackPressed: () => Navigator.of(context).maybePop(),
        backIcon: Icons.arrow_back_ios_new_rounded,
        title: context.l10n.scanIdentityVerification,
        titleStyle: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: context.appPalette.textPrimary,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(
                'VERIFICATION PROGRESS',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: context.appPalette.primary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      stepLabel,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: context.appPalette.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    stepCount,
                    style: TextStyle(
                      fontSize: 22 / 1.4,
                      fontWeight: FontWeight.w500,
                      color: context.appPalette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: context.appPalette.stroke,
                  color: context.appPalette.primary,
                ),
              ),
            ),
            const SizedBox(height: 34),
            Container(
              height: 236,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF7DA4E8), width: 4),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF878C95), Color(0xFFB4B9C1)],
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.82),
                    width: 3,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: Center(
                  child: Text(
                    _idStep == 1
                        ? 'POSITION ID FRONT HERE'
                        : 'POSITION ID BACK HERE',
                    style: TextStyle(
                      fontSize: 36 / 1.9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.2,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 36),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _idStep == 1 ? 'Scan Front of ID' : 'Scan Back of ID',
                style: TextStyle(
                  fontSize: 58 / 1.4,
                  fontWeight: FontWeight.w700,
                  color: context.appPalette.textPrimary,
                ),
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _idStep == 1
                    ? 'Make sure all details are clear and fit within the frame to avoid glare.'
                    : 'Capture the back side with all security details visible.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: context.appPalette.textSecondary,
                  height: 1.3,
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ControlBubble(
                    icon: Icons.photo_library_outlined,
                    label: 'GALLERY',
                    onTap: () => _finish(pagesCount: 2),
                  ),
                  _MainCaptureButton(onTap: _capture),
                  _ControlBubble(
                    icon: _flashEnabled
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    label: 'FLASH',
                    onTap: () {
                      setState(() {
                        _flashEnabled = !_flashEnabled;
                      });
                    },
                  ),
                ],
              ),
            ),
            if (_showFrontCapturedBanner)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF06173D),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF173A80)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D2F73),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.copy_all_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Front captured successfully\nNext: Flip card for Back Side',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    FilledButton(
                      onPressed: _continueIdBackStep,
                      style: FilledButton.styleFrom(
                        backgroundColor: context.appPalette.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'CONTINUE',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _captureSession(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appPalette.background,
      appBar: GenericAppBar(
        backgroundColor: context.appPalette.background,
        onBackPressed: () => Navigator.of(context).maybePop(),
        backIcon: Icons.close_rounded,
        title: _captureTitle(),
        titleStyle: TextStyle(
          fontSize: 32 / 1.4,
          fontWeight: FontWeight.w700,
          color: context.appPalette.textPrimary,
        ),
        actions: [
          TextButton(
            onPressed: _capturedPages == 0
                ? null
                : () => _finish(pagesCount: _capturedPages),
            child: const Text(
              'Done',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
        showDivider: false,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0E1119), Color(0xFF1A1E28)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(20, 90, 20, 170),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: context.appPalette.primary,
                              width: 4,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 26,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Align document within frame',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 18,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _DarkCircleButton(
                            icon: Icons.photo_library_outlined,
                            onTap: () => _finish(
                              pagesCount: _capturedPages == 0
                                  ? 1
                                  : _capturedPages,
                            ),
                          ),
                          _MainCaptureButton(onTap: _capture),
                          _DarkCircleButton(
                            icon: _flashEnabled
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded,
                            onTap: () {
                              setState(() {
                                _flashEnabled = !_flashEnabled;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'CAPTURED PAGES ($_capturedPages)',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
                          color: context.appPalette.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _capturedPages > 1 ? () {} : null,
                        child: const Text(
                          'REORDER',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 148,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _capturedPages + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _AddPageCard(onTap: _capture);
                        }
                        return _PageThumb(index: index);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _capturedPages == 0
                          ? null
                          : () => _finish(pagesCount: _capturedPages),
                      icon: Icon(Icons.check_circle_outline_rounded),
                      label: Text(
                        'Finish and Save',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: context.appPalette.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _capture() async {
    if (_isScanning) {
      return;
    }

    if (_nativeScannerSupported) {
      await _captureWithNativeScanner();
      return;
    }

    final confirmed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _AdjustDocumentPage(
          currentStep: _idStep,
          totalSteps: _isIdCard ? 2 : 3,
        ),
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    if (_isIdCard && _idStep == 1) {
      setState(() {
        _capturedPages += 1;
        _showFrontCapturedBanner = true;
      });
      return;
    }

    setState(() {
      _capturedPages += 1;
      _showCaptureSession = true;
    });
  }

  bool get _nativeScannerSupported {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  Future<void> _captureWithNativeScanner() async {
    setState(() {
      _isScanning = true;
    });
    try {
      final pickedFiles = await _pickScanImages();
      if (pickedFiles.isEmpty) {
        _showSnack('Scan cancelled.');
        return;
      }
      if (!mounted) {
        return;
      }

      setState(() {
        _capturedPages += pickedFiles.length;
        _showCaptureSession = true;
      });

      if (_isIdCard && _idStep == 1) {
        setState(() {
          _showFrontCapturedBanner = true;
        });
      }
    } on PlatformException catch (error) {
      _showSnack(_scannerErrorMessage(error));
    } catch (_) {
      _showSnack('Unable to open scanner right now.');
    } finally {
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
                title: Text(context.l10n.scanTakePhoto),
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

  String _scannerErrorMessage(PlatformException error) {
    if (error.code == 'UNAVAILABLE') {
      return 'Scanner unavailable on this device. Use a real iPhone/Android device.';
    }
    final message = error.message?.trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }
    return 'Scanner failed. Please retry.';
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _continueIdBackStep() {
    setState(() {
      _showFrontCapturedBanner = false;
      _idStep = 2;
    });
  }

  String _captureTitle() {
    return switch (widget.type) {
      DocumentType.passport => 'Passport Documents',
      DocumentType.idCard => 'ID Verification',
      DocumentType.driversLicense => "Driver's License",
      DocumentType.other => 'Other Documents',
    };
  }

  void _finish({required int pagesCount}) {
    Navigator.of(
      context,
    ).pop(DocumentScanFlowResult(pagesCount: pagesCount < 1 ? 1 : pagesCount));
  }
}

class _AdjustDocumentPage extends StatelessWidget {
  const _AdjustDocumentPage({
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appPalette.background,
      appBar: GenericAppBar(
        backgroundColor: context.appPalette.background,
        centerTitle: false,
        onBackPressed: () => Navigator.of(context).pop(false),
        backIcon: Icons.arrow_back_ios_new_rounded,
        title: context.l10n.scanAdjustDocument,
        titleStyle: TextStyle(
          fontSize: 42 / 1.4,
          fontWeight: FontWeight.w700,
          color: context.appPalette.textPrimary,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Text(
                'Step $currentStep of $totalSteps',
                style: TextStyle(
                  fontSize: 34 / 1.8,
                  fontWeight: FontWeight.w600,
                  color: context.appPalette.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 18),
            Container(
              height: 430,
              margin: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3D424E), Color(0xFF595F6D)],
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(34),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.appPalette.primary, width: 3),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Text(
                        'Crop area preview',
                        style: TextStyle(color: Color(0x99FFFFFF)),
                      ),
                    ),
                    Positioned(left: -1, top: -1, child: _HandleCircle()),
                    const Positioned(
                      right: -1,
                      top: -1,
                      child: _HandleCircle(),
                    ),
                    const Positioned(
                      left: -1,
                      bottom: -1,
                      child: _HandleCircle(),
                    ),
                    const Positioned(
                      right: -1,
                      bottom: -1,
                      child: _HandleCircle(),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: Icon(Icons.replay_rounded),
                      label: Text(context.l10n.scanRetake),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.appPalette.textPrimary,
                        side: BorderSide(color: context.appPalette.stroke),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    'Confirm Crop',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.appPalette.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Drag corners to align with document edges for the best OCR results.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.appPalette.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlBubble extends StatelessWidget {
  const _ControlBubble({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 94,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: context.appPalette.surfaceSoft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: const Color(0xFF3E4F69), size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15 / 1.2,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5A6A81),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainCaptureButton extends StatelessWidget {
  const _MainCaptureButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 112,
        height: 112,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.appPalette.primary,
          border: Border.all(color: const Color(0xFFBFD8FF), width: 6),
          boxShadow: const [
            BoxShadow(
              color: Color(0x252A1464),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.camera_alt_rounded,
          color: Colors.white,
          size: 44,
        ),
      ),
    );
  }
}

class _DarkCircleButton extends StatelessWidget {
  const _DarkCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF3C3127).withValues(alpha: 0.75),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 34 / 1.4),
      ),
    );
  }
}

class _AddPageCard extends StatelessWidget {
  const _AddPageCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 126,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: context.appPalette.stroke,
            width: 2,
            style: BorderStyle.solid,
          ),
          color: context.appPalette.surfaceSoft,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle, color: context.appPalette.primary, size: 38),
            SizedBox(height: 12),
            Text(
              'ADD PAGE',
              style: TextStyle(
                fontSize: 19 / 1.3,
                fontWeight: FontWeight.w700,
                color: context.appPalette.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageThumb extends StatelessWidget {
  const _PageThumb({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 136,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appPalette.stroke),
        color: context.appPalette.surfaceSoft,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 82,
            height: 98,
            decoration: BoxDecoration(
              color: context.appPalette.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: context.appPalette.stroke),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.description_outlined,
              color: context.appPalette.textSecondary,
              size: 32,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Page $index',
            style: TextStyle(
              fontSize: 17 / 1.25,
              fontWeight: FontWeight.w600,
              color: context.appPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HandleCircle extends StatelessWidget {
  const _HandleCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.appPalette.primary,
        border: Border.all(color: Colors.white, width: 3),
      ),
    );
  }
}
