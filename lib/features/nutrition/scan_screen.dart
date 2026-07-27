import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/nutrition/barcode_lookup.dart';
import '../../core/nutrition/label_parser.dart';
import '../../data/food_library.dart';
import '../../models/food_entry.dart';
import '../../models/ingredient.dart';
import '../../models/personal_food.dart';
import '../../models/saved_food_combo.dart';
import '../../models/scanned_product.dart';
import '../../repositories/nutrition_repository.dart';
import 'personal_food_editor_screen.dart';
import 'scan_review_screen.dart';

/// What happens after an item is scanned and reviewed.
enum ScanResultMode {
  /// Review the parsed values, then log to today's food log (the original
  /// behavior).
  logToday,

  /// Review the parsed values, then pop this screen with the resulting
  /// [Ingredient] — used by the recipe builder to add a scanned item to a
  /// combo.
  pickIngredient,

  /// Review the parsed values plus a name, then save directly as a
  /// reusable single-ingredient snack — for something you eat often (a
  /// protein bar) so you never have to rescan it.
  saveAsSnack,

  /// Review the parsed values (normalized to per-100g, no "grams eaten"
  /// question), then hand them to the personal food editor as a prefilled
  /// draft — for adding something to the food library that isn't in it,
  /// starting from a scan instead of typing every macro by hand.
  savePersonalFood,
}

enum _ScanMode { barcode, label }

class ScanScreen extends StatefulWidget {
  final ScanResultMode mode;

  const ScanScreen({super.key, this.mode = ScanResultMode.logToday});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

/// Where a tap on the shutter is in the label-scan sequence — used to drive
/// both the on-screen copy and the scan-line animation.
enum _ScanPhase { idle, settling, capturing, analyzing }

extension on _ScanPhase {
  String? get label {
    switch (this) {
      case _ScanPhase.idle:
        return null;
      case _ScanPhase.settling:
        return 'Hold steady…';
      case _ScanPhase.capturing:
        return 'Reading label…';
      case _ScanPhase.analyzing:
        return 'Analyzing…';
    }
  }
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _shotCount = 3;
  static const _barcodeFormats = [
    BarcodeFormat.ean13,
    BarcodeFormat.ean8,
    BarcodeFormat.upcA,
    BarcodeFormat.upcE,
  ];

  _ScanMode _mode = _ScanMode.barcode;

  // Barcode mode.
  MobileScannerController? _barcodeController;
  bool _barcodeBusy = false;

  // Label mode.
  CameraController? _labelController;
  Future<void>? _initFuture;
  late final AnimationController _scanLineController;
  _ScanPhase _phase = _ScanPhase.idle;
  bool _torchOn = false;
  Offset? _focusPoint;

  /// On some devices, OCR can never succeed no matter how many times you
  /// retry. After a couple of failures in a row, keep pointing the user at
  /// "try again" less and at manual entry (or the barcode toggle above)
  /// more, rather than implying one more tap will fix it.
  int _consecutiveFailures = 0;

  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _startBarcodeMode();
  }

  void _startBarcodeMode() {
    _barcodeController = MobileScannerController(formats: _barcodeFormats);
  }

  Future<void> _startLabelMode() async {
    _initFuture = _initCamera();
  }

  Future<void> _switchMode(_ScanMode mode) async {
    if (mode == _mode) return;
    setState(() => _mode = mode);

    if (mode == _ScanMode.barcode) {
      await _labelController?.dispose();
      _labelController = null;
      _startBarcodeMode();
    } else {
      await _barcodeController?.dispose();
      _barcodeController = null;
      await _startLabelMode();
    }
    if (mounted) setState(() {});
  }

  /// The camera plugin recommends releasing the controller while the app is
  /// backgrounded and re-acquiring it on resume — without this, a stale
  /// controller from before backgrounding can throw once the screen is
  /// interacted with again. [MobileScannerController] needs the same
  /// handling ourselves since passing our own controller opts out of its
  /// built-in lifecycle observer.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (_mode == _ScanMode.label) {
        _labelController?.dispose();
        if (mounted) setState(() => _labelController = null);
      } else {
        _barcodeController?.stop();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_mode == _ScanMode.label) {
        if (mounted) setState(() => _initFuture = _initCamera());
      } else {
        _barcodeController?.start();
      }
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No camera available on this device.');
        return;
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      // Nutrition labels are small, dense text — a sharper capture than the
      // default matters a lot more for OCR accuracy than it does for a
      // normal photo.
      final controller = CameraController(
        camera,
        ResolutionPreset.veryHigh,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() => _labelController = controller);
    } catch (e) {
      setState(() => _error = 'Could not access the camera: $e');
    }
  }

  Future<void> _toggleTorch() async {
    if (_mode == _ScanMode.barcode) {
      await _barcodeController?.toggleTorch();
      return;
    }
    final controller = _labelController;
    if (controller == null) return;
    final next = !_torchOn;
    try {
      await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _torchOn = next);
    } catch (_) {
      // No torch on this device/camera — leave the toggle as-is.
    }
  }

  Future<void> _focusAt(Offset normalized) async {
    final controller = _labelController;
    if (controller == null) return;
    setState(() => _focusPoint = normalized);
    try {
      await controller.setFocusPoint(normalized);
      await controller.setExposurePoint(normalized);
    } catch (_) {
      // Point focus/exposure isn't supported on this device — ignore.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _labelController?.dispose();
    _barcodeController?.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  /// Pushes the review screen with the given result, then routes the
  /// outcome per [widget.mode] — log to today, hand an [Ingredient] back to
  /// a recipe builder, or save it as a reusable snack.
  Future<void> _completeWithParsed(ParsedNutrition parsed,
      {String? name}) async {
    final wantsIngredient = widget.mode != ScanResultMode.logToday;
    final sheetResult = await showScanReviewScreen(
      context,
      parsed: parsed,
      pickerMode: wantsIngredient,
      normalizeTo100g: widget.mode == ScanResultMode.savePersonalFood,
      initialName: name,
    );

    if (!mounted) return;

    switch (widget.mode) {
      case ScanResultMode.logToday:
        if (sheetResult == true) Navigator.of(context).pop();
      case ScanResultMode.pickIngredient:
        if (sheetResult is Ingredient) Navigator.of(context).pop(sheetResult);
      case ScanResultMode.saveAsSnack:
        if (sheetResult is Ingredient) {
          final combo = SavedFoodCombo.fromIngredients(
            id: const Uuid().v4(),
            name: sheetResult.name,
            defaultMealType: MealType.snack,
            ingredients: [sheetResult],
            createdAt: DateTime.now(),
          );
          await context.read<NutritionRepository>().addCombo(combo);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${combo.name} saved to your snacks')),
          );
          Navigator.of(context).pop();
        }
      case ScanResultMode.savePersonalFood:
        if (sheetResult is Ingredient) {
          // Grams is fixed at 100 by normalizeTo100g, so the ingredient's
          // macros already *are* the per-100g values a personal food needs.
          final draft = PersonalFood(
            id: const Uuid().v4(),
            name: sheetResult.name,
            category: foodCategories.first,
            caloriesPer100g: sheetResult.calories,
            proteinPer100g: sheetResult.proteinG,
            carbsPer100g: sheetResult.carbsG,
            fatPer100g: sheetResult.fatG,
            fiberPer100g: sheetResult.fiberG,
            sugarPer100g: sheetResult.sugarG,
            sodiumMgPer100g: sheetResult.sodiumMg,
            createdAt: DateTime.now(),
          );
          final saved = await Navigator.of(context).push<PersonalFood>(
            MaterialPageRoute(
              builder: (_) => PersonalFoodEditorScreen(scannedDraft: draft),
            ),
          );
          if (!mounted) return;
          if (saved != null) Navigator.of(context).pop();
        }
    }
  }

  void _showManualEntryPrompt(String message) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Add manually',
          textColor: scheme.inversePrimary,
          onPressed: () {
            if (mounted) Navigator.of(context).pop();
          },
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  Future<void> _onBarcodeDetect(BarcodeCapture capture) async {
    if (_barcodeBusy || capture.barcodes.isEmpty) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _barcodeBusy = true);
    await _barcodeController?.pause();

    final result = await BarcodeLookup.lookup(code);
    if (!mounted) return;

    switch (result.status) {
      case BarcodeLookupStatus.found:
        await context.read<NutritionRepository>().upsertScannedProduct(
              ScannedProduct(
                barcode: code,
                name: result.productName!,
                calories: result.parsed!.calories,
                proteinG: result.parsed!.proteinG,
                carbsG: result.parsed!.carbsG,
                fatG: result.parsed!.fatG,
                fiberG: result.parsed!.fiberG,
                sugarG: result.parsed!.sugarG,
                sodiumMg: result.parsed!.sodiumMg,
                servingGrams: result.parsed!.servingGrams,
                lastScannedAt: DateTime.now(),
              ),
            );
        if (!mounted) return;
        await _completeWithParsed(result.parsed!, name: result.productName);
      case BarcodeLookupStatus.notFound:
        _showManualEntryPrompt(
          "No product found for that barcode — try the Label tab above, or add it manually.",
        );
      case BarcodeLookupStatus.error:
        _showManualEntryPrompt(
          "Couldn't reach the food database — check your connection, or add it manually.",
        );
    }

    if (mounted && _mode == _ScanMode.barcode) {
      setState(() => _barcodeBusy = false);
      await _barcodeController?.start();
    }
  }

  /// On this device, the camera's own JPEG output fails to decode inside
  /// Tesseract's native image loader (`Invalid SOS parameters for
  /// sequential JPEG`, confirmed via device logs) — a genuine mismatch
  /// between this camera pipeline's JPEG encoding and the decoder Tesseract
  /// uses internally, not an OCR accuracy issue. Flutter's own decoder
  /// (`dart:ui`) reads the same file fine, so re-encoding through it to PNG
  /// before handing the frame to Tesseract sidesteps the broken decoder
  /// entirely, the same fix this scanner needed for a different consumer
  /// (ML Kit) before the OCR engine was replaced.
  Future<String?> _reencodeAsPng(String path) async {
    ui.Image? image;
    ui.Codec? codec;
    try {
      final bytes = await File(path).readAsBytes();
      if (bytes.isEmpty) return null;

      codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      image = frame.image;

      final pngData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (pngData == null) return null;

      final pngPath = '$path.png';
      await File(pngPath).writeAsBytes(
        pngData.buffer
            .asUint8List(pngData.offsetInBytes, pngData.lengthInBytes),
      );
      return pngPath;
    } catch (e) {
      debugPrint('Re-encode to PNG failed: $e');
      return null;
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }

  Future<void> _captureLabel() async {
    final controller = _labelController;
    if (controller == null || _phase != _ScanPhase.idle) return;

    setState(() => _phase = _ScanPhase.settling);
    _scanLineController.repeat(reverse: true);

    try {
      // Give autofocus/exposure a moment to lock before the first shot,
      // then take a few frames instead of one instant snapshot — merging
      // several OCR passes reads a label more accurately than a single shot.
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      setState(() => _phase = _ScanPhase.capturing);
      final files = <XFile>[];
      for (var i = 0; i < _shotCount; i++) {
        files.add(await controller.takePicture());
      }

      if (!mounted) return;
      setState(() => _phase = _ScanPhase.analyzing);

      // Each frame is read independently — a single misread capture
      // shouldn't sink the whole scan when the other frames are fine.
      final parses = <ParsedNutrition>[];
      for (final file in files) {
        try {
          final ocrPath = await _reencodeAsPng(file.path);
          if (ocrPath == null)
            throw StateError('Could not decode frame for OCR');
          final text =
              await FlutterTesseractOcr.extractText(ocrPath, language: 'eng');
          parses.add(LabelParser.parse(text));
        } catch (e) {
          debugPrint('Skipping unreadable label frame: $e');
        }
      }
      if (parses.isEmpty) {
        throw StateError('None of the captures could be read');
      }
      _consecutiveFailures = 0;
      final parsed = LabelParser.merge(parses);

      if (!mounted) return;
      await _completeWithParsed(parsed);
    } catch (e, st) {
      // Never surface the raw exception/stack trace here — a long native
      // error string has no height cap in a SnackBar and effectively takes
      // over the screen. Log it for diagnosis, show a short message instead.
      debugPrint('Label scan failed: $e\n$st');
      _consecutiveFailures++;
      if (mounted) {
        final scheme = Theme.of(context).colorScheme;
        final persistentFailure = _consecutiveFailures >= 2;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              persistentFailure
                  ? "Still can't read labels on this device — try the Barcode tab above, or add it manually."
                  : "Couldn't read that label — try again.",
            ),
            action: persistentFailure
                ? SnackBarAction(
                    label: 'Add manually',
                    textColor: scheme.inversePrimary,
                    onPressed: () {
                      if (mounted) Navigator.of(context).pop();
                    },
                  )
                : null,
            duration: persistentFailure
                ? const Duration(seconds: 8)
                : const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      _scanLineController.stop();
      if (mounted) setState(() => _phase = _ScanPhase.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan food'),
        actions: [
          IconButton(
            tooltip: 'Toggle flash',
            icon: const Icon(Icons.flash_on),
            onPressed: _toggleTorch,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SegmentedButton<_ScanMode>(
              segments: const [
                ButtonSegment(
                  value: _ScanMode.barcode,
                  label: Text('Barcode'),
                  icon: Icon(LucideIcons.barcode),
                ),
                ButtonSegment(
                  value: _ScanMode.label,
                  label: Text('Label'),
                  icon: Icon(Icons.camera_alt_outlined),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) => _switchMode(selection.first),
            ),
          ),
          Expanded(
            child: _mode == _ScanMode.barcode
                ? _buildBarcodeBody()
                : _buildLabelBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBarcodeBody() {
    final controller = _barcodeController;
    if (controller == null) return const SizedBox.shrink();

    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(controller: controller, onDetect: _onBarcodeDetect),
        Positioned(
          left: 24,
          right: 24,
          top: 24,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_barcodeBusy) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    _barcodeBusy
                        ? 'Looking up product…'
                        : 'Point the camera at a barcode.',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabelBody() {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (_error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final controller = _labelController;
        if (controller == null || !controller.value.isInitialized) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.white));
        }

        final scanning = _phase != _ScanPhase.idle;

        return LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final focusPoint = _focusPoint;

            return Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: scanning
                      ? null
                      : (details) => _focusAt(
                            Offset(
                              details.localPosition.dx / size.width,
                              details.localPosition.dy / size.height,
                            ),
                          ),
                  child: CameraPreview(controller),
                ),
                if (focusPoint != null)
                  Positioned(
                    left: focusPoint.dx * size.width - 32,
                    top: focusPoint.dy * size.height - 32,
                    child: IgnorePointer(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                if (scanning && _phase != _ScanPhase.analyzing)
                  Positioned.fill(
                      child: _ScanLine(animation: _scanLineController)),
                Positioned(
                  left: 24,
                  right: 24,
                  top: 24,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_phase == _ScanPhase.analyzing) ...[
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Flexible(
                          child: Text(
                            _phase.label ??
                                'Frame the nutrition facts panel, then capture.',
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 32 + MediaQuery.of(context).padding.bottom,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Semantics(
                      button: true,
                      label: 'Capture photo',
                      child: GestureDetector(
                        onTap: scanning ? null : _captureLabel,
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.white38, width: 4),
                          ),
                          child: scanning
                              ? const Padding(
                                  padding: EdgeInsets.all(20),
                                  child:
                                      CircularProgressIndicator(strokeWidth: 3),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// A soft horizontal line that sweeps up and down over the camera preview
/// while a scan is in progress, giving visual feedback that the app is
/// actively reading the label rather than appearing to hang.
class _ScanLine extends StatelessWidget {
  final Animation<double> animation;

  const _ScanLine({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Align(
          alignment: Alignment(0, -1 + 2 * animation.value),
          child: Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [
                  Colors.greenAccent.withValues(alpha: 0),
                  Colors.greenAccent,
                  Colors.greenAccent.withValues(alpha: 0),
                ],
              ),
              boxShadow: const [
                BoxShadow(color: Colors.greenAccent, blurRadius: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
