import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../data/muscle_regions.dart';
import '../models/user_profile.dart';

/// Front+back muscle diagram for the "Body Rank" screen, built from a
/// licensed-for-personal-use line-art asset (`assets/body_rank/<sex>/`)
/// rather than hand-coded shapes: `mask_<region>.png` is a per-region alpha
/// stencil, filled with a flat rank color, and `lineart.png` is a
/// transparent-background outline-only layer drawn on top — the accurate
/// muscle boundary lines from the source art always win visually, even
/// where an individual region mask is a little imprecise underneath.
///
/// Tapping the diagram hit-tests against the same per-region alpha masks
/// used to paint it (see [_BodyAssets.regionAt]), so the tappable area for
/// each muscle matches its visible shape exactly instead of an approximate
/// bounding box.
class MuscleBodyDiagram extends StatefulWidget {
  final Map<MuscleRegion, MuscleRankTier> ranks;
  final Sex sex;
  final MuscleRegion? selectedRegion;
  final ValueChanged<MuscleRegion?>? onRegionTap;

  const MuscleBodyDiagram({
    super.key,
    required this.ranks,
    this.sex = Sex.male,
    this.selectedRegion,
    this.onRegionTap,
  });

  @override
  State<MuscleBodyDiagram> createState() => _MuscleBodyDiagramState();
}

class _MuscleBodyDiagramState extends State<MuscleBodyDiagram> {
  // Cached per sex at the class level (not per-instance) so these small
  // PNGs are decoded once for the lifetime of the app, not reloaded every
  // time this widget rebuilds or remounts.
  static final Map<Sex, Future<_BodyAssets>> _assetsFutures = {};

  void _handleTapUp(TapUpDetails details, Size renderSize, _BodyAssets assets) {
    final onRegionTap = widget.onRegionTap;
    if (onRegionTap == null) return;

    final imageSize =
        Size(assets.lineart.width.toDouble(), assets.lineart.height.toDouble());
    final imagePoint = Offset(
      details.localPosition.dx / renderSize.width * imageSize.width,
      details.localPosition.dy / renderSize.height * imageSize.height,
    );
    final tapped = assets.regionAt(imagePoint);
    // Tapping the same region again deselects it, matching the toggle
    // behavior of tapping a region's name in the list below the diagram.
    onRegionTap(tapped == widget.selectedRegion ? null : tapped);
  }

  @override
  Widget build(BuildContext context) {
    final assetsFuture = _assetsFutures.putIfAbsent(
        widget.sex, () => _BodyAssets.load(widget.sex));
    return FutureBuilder<_BodyAssets>(
      future: assetsFuture,
      builder: (context, snapshot) {
        final assets = snapshot.data;
        return AspectRatio(
          // Matches the source art's own proportions while loading, so
          // there's no layout jump once the images resolve.
          aspectRatio: assets != null
              ? assets.lineart.width / assets.lineart.height
              : 1100 / 910,
          child: assets == null
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final renderSize = constraints.biggest;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) =>
                          _handleTapUp(details, renderSize, assets),
                      child: CustomPaint(
                        painter: _MuscleBodyPainter(
                          assets: assets,
                          ranks: widget.ranks,
                          selectedRegion: widget.selectedRegion,
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _BodyAssets {
  final ui.Image lineart;
  final Map<MuscleRegion, ui.Image> masks;
  final Map<MuscleRegion, ByteData> maskAlpha;

  const _BodyAssets(
      {required this.lineart, required this.masks, required this.maskAlpha});

  static const _regionFiles = {
    MuscleRegion.chest: 'chest',
    MuscleRegion.shoulders: 'shoulders',
    MuscleRegion.biceps: 'biceps',
    MuscleRegion.triceps: 'triceps',
    MuscleRegion.forearms: 'forearms',
    MuscleRegion.abs: 'abs',
    MuscleRegion.lats: 'lats',
    MuscleRegion.traps: 'traps',
    MuscleRegion.lowerBack: 'lowerback',
    MuscleRegion.glutes: 'glutes',
    MuscleRegion.quads: 'quads',
    MuscleRegion.hamstrings: 'hamstrings',
    MuscleRegion.calves: 'calves',
  };

  static Future<_BodyAssets> load(Sex sex) async {
    final dir = sex == Sex.female ? 'female' : 'male';
    final lineart = await _loadImage('assets/body_rank/$dir/lineart.png');
    final masks = <MuscleRegion, ui.Image>{};
    final maskAlpha = <MuscleRegion, ByteData>{};
    for (final entry in _regionFiles.entries) {
      final mask =
          await _loadImage('assets/body_rank/$dir/mask_${entry.value}.png');
      masks[entry.key] = mask;
      // Decoded once up front (not per-tap) so hit-testing in
      // [regionAt] is a synchronous byte lookup, not an async re-decode.
      maskAlpha[entry.key] =
          (await mask.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    }
    return _BodyAssets(lineart: lineart, masks: masks, maskAlpha: maskAlpha);
  }

  static Future<ui.Image> _loadImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Which region (if any) has a non-transparent mask pixel at [imagePoint]
  /// (in the lineart's own pixel coordinates, not the rendered widget size).
  MuscleRegion? regionAt(Offset imagePoint) {
    final x = imagePoint.dx.round();
    final y = imagePoint.dy.round();
    final width = lineart.width;
    final height = lineart.height;
    if (x < 0 || y < 0 || x >= width || y >= height) return null;

    for (final entry in maskAlpha.entries) {
      final alphaIndex = (y * width + x) * 4 + 3;
      if (alphaIndex >= entry.value.lengthInBytes) continue;
      if (entry.value.getUint8(alphaIndex) > 10) return entry.key;
    }
    return null;
  }
}

class _MuscleBodyPainter extends CustomPainter {
  final _BodyAssets assets;
  final Map<MuscleRegion, MuscleRankTier> ranks;
  final MuscleRegion? selectedRegion;

  _MuscleBodyPainter(
      {required this.assets, required this.ranks, this.selectedRegion});

  @override
  void paint(Canvas canvas, Size size) {
    final imageSize =
        Size(assets.lineart.width.toDouble(), assets.lineart.height.toDouble());
    final imageRect = Offset.zero & imageSize;

    canvas.save();
    canvas.scale(size.width / imageSize.width, size.height / imageSize.height);

    for (final entry in assets.masks.entries) {
      final tier = ranks[entry.key] ?? MuscleRankTier.novice;
      final maskImage = entry.value;

      if (tier == MuscleRankTier.legendary) {
        // Gradients can't go through a ColorFilter, so this one needs an
        // offscreen layer: draw the mask, recolor it with the gradient via
        // srcIn, then composite that layer as a flat fill.
        canvas.saveLayer(imageRect, Paint());
        canvas.drawImage(maskImage, Offset.zero, Paint());
        canvas.drawRect(
          imageRect,
          Paint()
            ..shader = ui.Gradient.linear(
              imageRect.topLeft,
              imageRect.bottomRight,
              const [Color(0xFF8E24AA), Color(0xFFE91E63), Color(0xFF00BCD4)],
              const [0.0, 0.5, 1.0],
            )
            ..blendMode = BlendMode.srcIn,
        );
        canvas.restore();
      } else {
        canvas.drawImage(
          maskImage,
          Offset.zero,
          Paint()..colorFilter = ColorFilter.mode(tier.color, BlendMode.srcIn),
        );
      }
    }

    // Outline-only line art on top — its accurate muscle boundaries win
    // visually over any imprecision in the individual region masks below.
    canvas.drawImage(assets.lineart, Offset.zero, Paint());

    // A soft additive glow around the selected region's own mask shape, on
    // top of everything else — lights the tapped muscle up without hiding
    // the line art or its rank color underneath. Same visual regardless of
    // whether the tap came from the diagram itself or the region's name in
    // the list below it (see body_rank_screen.dart).
    final selected = selectedRegion;
    if (selected != null) {
      final maskImage = assets.masks[selected];
      if (maskImage != null) {
        canvas.drawImage(
          maskImage,
          Offset.zero,
          Paint()
            ..colorFilter =
                const ColorFilter.mode(Color(0xFFFFEB3B), BlendMode.srcIn)
            ..imageFilter = ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14)
            ..blendMode = BlendMode.plus,
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MuscleBodyPainter oldDelegate) =>
      oldDelegate.ranks != ranks ||
      oldDelegate.selectedRegion != selectedRegion;
}
