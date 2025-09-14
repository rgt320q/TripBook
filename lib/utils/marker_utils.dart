import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<BitmapDescriptor> getHomeMarkerIcon({double size = 30}) async {
  final PictureRecorder pictureRecorder = PictureRecorder();
  final Canvas canvas = Canvas(
    pictureRecorder,
    Rect.fromPoints(Offset.zero, Offset(size, size)),
  );
  final double radius = size / 2;

  // Draw a perfect circle as the base
  final Paint fillPaint = Paint()..color = Colors.indigo; // Home color
  canvas.drawCircle(Offset(radius, radius), radius, fillPaint);

  // Pin Border
  final Paint borderPaint = Paint()
    ..color = Colors.white
    ..strokeWidth = size * 0.03
    ..style = PaintingStyle.stroke;
  canvas.drawCircle(Offset(radius, radius), radius, borderPaint);

  // Draw the home icon inside
  final iconData = Icons.home_filled;
  final textPainter = TextPainter(textDirection: TextDirection.ltr);
  textPainter.text = TextSpan(
    text: String.fromCharCode(iconData.codePoint),
    style: TextStyle(
      fontSize: size * 0.5, // Adjust font size to fit well
      fontFamily: iconData.fontFamily,
      color: Colors.white,
    ),
  );
  textPainter.layout();
  // Center the icon within the circle
  textPainter.paint(
    canvas,
    Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
  );

  final img = await pictureRecorder.endRecording().toImage(
    size.toInt(),
    size.toInt(),
  );
  final data = await img.toByteData(format: ImageByteFormat.png);

  return BitmapDescriptor.bytes(data!.buffer.asUint8List());
}

Future<BitmapDescriptor> getCustomMarkerIcon(
  Color color, {
  double size = 40,
  bool isEndpoint = false,
}) async {
  final PictureRecorder pictureRecorder = PictureRecorder();
  // Gölgenin kırpılmasını önlemek için canvas'ı biraz daha büyük yapalım
  final Canvas canvas = Canvas(
    pictureRecorder,
    Rect.fromPoints(Offset.zero, Offset(size, size)),
  );

  // Materyal Tasarım ikonuna dayalı bir pin yolu (path) oluşturalım
  Path path = Path();
  path.moveTo(12.0, 2.0);
  path.cubicTo(8.13, 2.0, 5.0, 5.13, 5.0, 9.0);
  path.cubicTo(5.0, 14.25, 12.0, 22.0, 12.0, 22.0);
  path.cubicTo(12.0, 22.0, 19.0, 14.25, 19.0, 9.0);
  path.cubicTo(19.0, 5.13, 15.87, 2.0, 12.0, 2.0);
  path.close();

  // Yolu istenen boyuta ölçeklendirelim
  final double scale =
      size / 24.0; // Orijinal yol 24x24 bir alana göre tanımlanmıştır
  final Matrix4 matrix = Matrix4.identity()..scale(scale);
  final Path scaledPath = path.transform(matrix.storage);

  // --- Çizim ---

  // 1. Gölge çizelim
  final Paint shadowPaint = Paint()
    ..color = Colors.black.withAlpha(64)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  canvas.drawPath(scaledPath, shadowPaint);

  // 2. Pin gövdesini (dolgu) çizelim
  final Paint fillPaint = Paint()..color = color;
  canvas.drawPath(scaledPath, fillPaint);

  // 3. Pin kenarlığını çizelim
  final Paint borderPaint = Paint()
    ..color = Colors.black.withAlpha(204)
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;
  canvas.drawPath(scaledPath, borderPaint);

  // 4. İçteki beyaz daireyi veya bayrağı çizelim
  if (isEndpoint) {
    final iconData = Icons.flag;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: size * 0.5,
        fontFamily: iconData.fontFamily,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
    );
  } else {
    final Paint innerCirclePaint = Paint()..color = Colors.white;
    // Orijinal 24x24 yoldaki dairenin merkezi (12, 9.5)'tur
    final Offset circleCenter = Offset(12.0 * scale, 9.5 * scale);
    final double circleRadius = 2.5 * scale;
    canvas.drawCircle(circleCenter, circleRadius, innerCirclePaint);
  }

  // Canvas'ı resme dönüştürelim
  final img = await pictureRecorder.endRecording().toImage(
    size.toInt(),
    size.toInt(),
  );
  final data = await img.toByteData(format: ImageByteFormat.png);

  return BitmapDescriptor.bytes(data!.buffer.asUint8List());
}

Future<BitmapDescriptor> getCurrentLocationMarkerIcon({
  double size = 30,
}) async {
  final PictureRecorder pictureRecorder = PictureRecorder();
  final Canvas canvas = Canvas(
    pictureRecorder,
    Rect.fromPoints(Offset.zero, Offset(size, size)),
  );
  final double radius = size / 2;

  // 1. Dışarıdaki yarı saydam "aura"yı çizelim
  final Paint auraPaint = Paint()..color = Colors.blue.withAlpha(64);
  canvas.drawCircle(Offset(radius, radius), radius, auraPaint);

  // 2. Ana mavi noktayı çizelim
  final Paint fillPaint = Paint()
    ..color = const Color(0xFF4285F4); // Google Mavisi
  canvas.drawCircle(Offset(radius, radius), radius * 0.7, fillPaint);

  // 3. Ana noktanın beyaz kenarlığını çizelim
  final Paint borderPaint = Paint()
    ..color = Colors.white
    ..strokeWidth = size * 0.06
    ..style = PaintingStyle.stroke;
  canvas.drawCircle(Offset(radius, radius), radius * 0.7, borderPaint);

  // Canvas'ı resme dönüştürelim
  final img = await pictureRecorder.endRecording().toImage(
    size.toInt(),
    size.toInt(),
  );
  final data = await img.toByteData(format: ImageByteFormat.png);

  return BitmapDescriptor.bytes(data!.buffer.asUint8List());
}
