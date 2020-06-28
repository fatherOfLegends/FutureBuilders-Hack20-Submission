import 'package:flame/game.dart';
import 'package:flame/gestures.dart';
import 'package:flame/util.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  Util flameUtil = Util();
  WidgetsFlutterBinding.ensureInitialized();
  await flameUtil.fullScreen();
  await flameUtil.setOrientation(DeviceOrientation.portraitUp);

  BoxGame game = BoxGame();
  runApp(game.widget);
}

class BoxGame extends Game with TapDetector {
  Size screenSize;
  bool hasWon = false;
  int currentTime = 0;

  double get height => screenSize.height;
  double get width => screenSize.width;

  void render(Canvas canvas) {
    _drawBackground(canvas);
    _drawGamePlane(canvas);

    Paint boxPaint = Paint();
    if (hasWon) {
      boxPaint.color = Color(0xfffe00fe);
    } else {
      boxPaint.color = Color(0xff00b3fe);
    }
  }

  void _drawGamePlane(Canvas canvas) {
    Paint linePaint = Paint()
      ..color = Color(0xfffe00fe)
      ..strokeWidth = 2;
    final lineSpacing = 60.0;
    final speedFactor = currentTime % 400 / 400;
    final movementAmount = (lineSpacing * speedFactor).floorToDouble();
    double lastLineY = height + movementAmount;
    final horizonY = height * .6;
    canvas.drawLine(Offset(0, lastLineY), Offset(width, lastLineY), linePaint);
    while (lastLineY > horizonY * 1.04) {
      final factor = (lastLineY - horizonY) / horizonY;
      final lineY = lastLineY - lineSpacing * factor;
      canvas.drawLine(Offset(0, lineY), Offset(width, lineY), linePaint);
      lastLineY = lineY;
    }

    final centerX = width / 2;
    canvas.drawLine(Offset(centerX, height), Offset(centerX, horizonY * 1.04), linePaint);
    for (int i = 1; i < 10; i++) {
      double topSpacing = lineSpacing * .3 * i;
      double bottomSpacing = lineSpacing * i;
      canvas.drawLine(
          Offset(centerX - bottomSpacing, height), Offset(centerX - topSpacing, horizonY * 1.04), linePaint);
      canvas.drawLine(
          Offset(centerX + bottomSpacing, height), Offset(centerX + topSpacing, horizonY * 1.04), linePaint);
    }
  }

  void _drawBackground(Canvas canvas) {
    Rect bgRect = Rect.fromLTWH(0, 0, screenSize.width, screenSize.height);
    Paint bgPaint = Paint();
    bgPaint.color = Color(0xff000000);
    canvas.drawRect(bgRect, bgPaint);
  }

  void update(double t) {
    currentTime += (t * 1000).toInt();
  }

  void resize(Size size) {
    screenSize = size;
    super.resize(size);
  }

  @override
  void onTapDown(TapDownDetails d) {
    double screenCenterX = screenSize.width / 2;
    double screenCenterY = screenSize.height / 2;
    if (d.globalPosition.dx >= screenCenterX - 75 &&
        d.globalPosition.dx <= screenCenterX + 75 &&
        d.globalPosition.dy >= screenCenterY - 75 &&
        d.globalPosition.dy <= screenCenterY + 75) {
      hasWon = true;
    } else {
      hasWon = false;
    }
  }
}
