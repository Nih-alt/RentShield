// Standalone Dart script to generate a premium app icon for Rent Shield.
// Generates a 1024x1024 PNG with a shield motif on deep slate background.
//
// Run: dart pub add image --dev && dart run tool/generate_icon.dart

import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() {
  const size = 1024;
  final image = img.Image(width: size, height: size);

  // Background: deep slate primary #1A2B3D
  final bg = img.ColorRgba8(0x1A, 0x2B, 0x3D, 0xFF);
  img.fill(image, color: bg);

  // Draw a subtle radial gradient overlay for depth
  final cx = size / 2;
  final cy = size / 2;
  final maxDist = size * 0.55;
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final dist = sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy));
      if (dist < maxDist) {
        final t = 1.0 - (dist / maxDist);
        final boost = (t * t * 18).round().clamp(0, 25);
        final pixel = image.getPixel(x, y);
        final r = (pixel.r.toInt() + boost).clamp(0, 255);
        final g = (pixel.g.toInt() + boost).clamp(0, 255);
        final b = (pixel.b.toInt() + boost).clamp(0, 255);
        image.setPixel(x, y, img.ColorRgba8(r, g, b, 0xFF));
      }
    }
  }

  // Shield shape - draw filled polygon
  // Shield centered, occupying ~60% of icon
  final shieldW = size * 0.50;
  final shieldH = size * 0.56;
  final shieldCx = size / 2;
  final shieldTop = size * 0.18;

  // Shield outline points (top-left to top-right, then down to point)
  // Using smooth curves approximated with segments
  final shieldPoints = <Point<double>>[];

  // Top edge (slightly curved)
  final topLeft = Point(shieldCx - shieldW / 2, shieldTop);
  final topRight = Point(shieldCx + shieldW / 2, shieldTop);

  // Left side curves in
  final midLeftY = shieldTop + shieldH * 0.55;
  final midLeft = Point(shieldCx - shieldW / 2, midLeftY);

  // Bottom point
  final bottomPoint = Point(shieldCx, shieldTop + shieldH);

  // Right side
  final midRight = Point(shieldCx + shieldW / 2, midLeftY);

  // Build shield path with bezier-like segments
  // Top edge
  for (double t = 0; t <= 1; t += 0.02) {
    final x = topLeft.x + (topRight.x - topLeft.x) * t;
    // Slight upward curve at center
    final curve = -8 * sin(t * pi);
    shieldPoints.add(Point(x, topLeft.y + curve));
  }

  // Right side down to mid
  for (double t = 0; t <= 1; t += 0.02) {
    final x = topRight.x + (midRight.x - topRight.x) * t * 0.05;
    final y = topRight.y + (midRight.y - topRight.y) * t;
    shieldPoints.add(Point(x, y));
  }

  // Right side mid to bottom point (curve inward)
  for (double t = 0; t <= 1; t += 0.01) {
    final x = midRight.x + (bottomPoint.x - midRight.x) * t;
    final y = midRight.y + (bottomPoint.y - midRight.y) * t;
    // Curve inward
    final curve = -20 * sin(t * pi) * (1 - t);
    shieldPoints.add(Point(x + curve, y));
  }

  // Bottom point to left mid (curve inward)
  for (double t = 0; t <= 1; t += 0.01) {
    final x = bottomPoint.x + (midLeft.x - bottomPoint.x) * t;
    final y = bottomPoint.y + (midLeft.y - bottomPoint.y) * t;
    final curve = 20 * sin(t * pi) * (1 - t);
    shieldPoints.add(Point(x + curve, y));
  }

  // Left side mid to top
  for (double t = 0; t <= 1; t += 0.02) {
    final x = midLeft.x + (topLeft.x - midLeft.x) * t * 0.05;
    final y = midLeft.y + (topLeft.y - midLeft.y) * t;
    shieldPoints.add(Point(x, y));
  }

  // Fill shield with warm caramel accent #D4A574
  final accentColor = img.ColorRgba8(0xD4, 0xA5, 0x74, 0xFF);
  _fillPolygon(image, shieldPoints, accentColor);

  // Draw shield border (slightly brighter)
  final borderColor = img.ColorRgba8(0xE0, 0xB8, 0x8A, 0xFF);
  _drawPolylineThick(image, shieldPoints, borderColor, 6);

  // Draw inner shield (smaller, darker)
  final innerScale = 0.78;
  final innerPoints = shieldPoints.map((p) {
    final dx = p.x - shieldCx;
    final dy = p.y - (shieldTop + shieldH * 0.42);
    return Point(
      shieldCx + dx * innerScale,
      (shieldTop + shieldH * 0.42) + dy * innerScale,
    );
  }).toList();

  final innerColor = img.ColorRgba8(0x1A, 0x2B, 0x3D, 0xFF);
  _fillPolygon(image, innerPoints, innerColor);
  final innerBorder = img.ColorRgba8(0xD4, 0xA5, 0x74, 0x99);
  _drawPolylineThick(image, innerPoints, innerBorder, 3);

  // Draw checkmark inside inner shield
  final checkCx = shieldCx;
  final checkCy = shieldTop + shieldH * 0.40;
  final checkSize = shieldW * 0.22;

  final checkPoints = [
    Point(checkCx - checkSize * 0.45, checkCy + checkSize * 0.05),
    Point(checkCx - checkSize * 0.08, checkCy + checkSize * 0.40),
    Point(checkCx + checkSize * 0.50, checkCy - checkSize * 0.35),
  ];

  // Draw thick checkmark
  final checkColor = img.ColorRgba8(0xD4, 0xA5, 0x74, 0xFF);
  _drawLineThick(image, checkPoints[0], checkPoints[1], checkColor, 14);
  _drawLineThick(image, checkPoints[1], checkPoints[2], checkColor, 14);

  // Draw "RS" text (simple pixel rendering since no font rasterizer)
  // Instead, draw a small horizontal line decoration under the check
  final decoY = (checkCy + checkSize * 0.65).round();
  final decoLeft = (checkCx - checkSize * 0.35).round();
  final decoRight = (checkCx + checkSize * 0.35).round();
  for (int x = decoLeft; x <= decoRight; x++) {
    for (int dy = -1; dy <= 1; dy++) {
      if (decoY + dy >= 0 && decoY + dy < size) {
        image.setPixel(x, decoY + dy, img.ColorRgba8(0xD4, 0xA5, 0x74, 0x66));
      }
    }
  }

  // Save
  final outPath = 'assets/icons/app_icon.png';
  final pngData = img.encodePng(image);
  File(outPath).writeAsBytesSync(pngData);
  print('Icon generated: $outPath (${pngData.length} bytes)');
}

void _fillPolygon(
    img.Image image, List<Point<double>> points, img.Color color) {
  if (points.isEmpty) return;

  double minY = double.infinity, maxY = double.negativeInfinity;
  for (final p in points) {
    if (p.y < minY) minY = p.y;
    if (p.y > maxY) maxY = p.y;
  }

  for (int y = minY.floor(); y <= maxY.ceil(); y++) {
    if (y < 0 || y >= image.height) continue;
    final intersections = <double>[];

    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      final p1 = points[i];
      final p2 = points[j];

      if ((p1.y <= y && p2.y > y) || (p2.y <= y && p1.y > y)) {
        final x = p1.x + (y - p1.y) / (p2.y - p1.y) * (p2.x - p1.x);
        intersections.add(x);
      }
    }

    intersections.sort();
    for (int k = 0; k + 1 < intersections.length; k += 2) {
      final x1 = intersections[k].floor().clamp(0, image.width - 1);
      final x2 = intersections[k + 1].ceil().clamp(0, image.width - 1);
      for (int x = x1; x <= x2; x++) {
        image.setPixel(x, y, color);
      }
    }
  }
}

void _drawPolylineThick(img.Image image, List<Point<double>> points,
    img.Color color, int thickness) {
  for (int i = 0; i < points.length - 1; i++) {
    _drawLineThick(image, points[i], points[i + 1], color, thickness);
  }
  // Close
  if (points.length > 2) {
    _drawLineThick(image, points.last, points.first, color, thickness);
  }
}

void _drawLineThick(img.Image image, Point<double> p1, Point<double> p2,
    img.Color color, int thickness) {
  final half = thickness / 2;
  final dx = p2.x - p1.x;
  final dy = p2.y - p1.y;
  final steps = max(dx.abs(), dy.abs()).ceil();
  if (steps == 0) return;

  for (int s = 0; s <= steps; s++) {
    final t = s / steps;
    final cx = p1.x + dx * t;
    final cy = p1.y + dy * t;

    for (int oy = (-half).floor(); oy <= half.ceil(); oy++) {
      for (int ox = (-half).floor(); ox <= half.ceil(); ox++) {
        if (ox * ox + oy * oy <= half * half) {
          final px = (cx + ox).round();
          final py = (cy + oy).round();
          if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
            image.setPixel(px, py, color);
          }
        }
      }
    }
  }
}
