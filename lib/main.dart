import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/anchor.dart';
import 'package:flame/components/component.dart';
import 'package:flame/components/mixins/has_game_ref.dart';
import 'package:flame/game.dart';
import 'package:flame/gestures.dart';
import 'package:flame/palette.dart';
import 'package:flame/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  Util flameUtil = Util();
  WidgetsFlutterBinding.ensureInitialized();
  await flameUtil.fullScreen();
  await flameUtil.setOrientation(DeviceOrientation.portraitUp);

  final game = MyGame();
  runApp(game.widget);
}

class Palette {
  static const PaletteEntry white = BasicPalette.white;
  static const PaletteEntry pink = PaletteEntry(Color(0xfffe00fe));
  static const PaletteEntry purple = PaletteEntry(Color(0xff7700a6));
  static const PaletteEntry blue = PaletteEntry(Color(0xff00b3fe));
}

class Square extends PositionComponent with HasGameRef<MyGame> {
  static const SPEED = 0.25;

  @override
  void resize(Size size) {
    x = size.width / 2;
    y = size.height / 2;
  }

  @override
  void render(Canvas c) {
    prepareCanvas(c);

    c.drawRect(Rect.fromLTWH(0, 0, width, height), Palette.white.paint);
    c.drawRect(const Rect.fromLTWH(0, 0, 3, 3), Palette.pink.paint);
    c.drawRect(Rect.fromLTWH(width / 2, height / 2, 3, 3), Palette.blue.paint);
  }

  @override
  void update(double t) {
    super.update(t);
    angle += SPEED * t;
    angle %= 2 * math.pi;
  }

  @override
  void onMount() {
    width = height = gameRef.squareSize;
    anchor = Anchor.bottomCenter;
  }
}

class MyGame extends BaseGame with TapDetector {
  final double squareSize = 128;
  bool running = true;
  Size screenSize;

  MyGame() {
    add(Ground());
    add(Square());
  }

  void resize(Size size) {
    screenSize = size;
    super.resize(size);
  }

  @override
  void onTap() {
    if (running) {
      pauseEngine();
    } else {
      resumeEngine();
    }

    running = !running;
  }
}

class Ground extends PositionComponent with HasGameRef<MyGame> {
  static const FRICTION = 3;
  static const ROTATION_SPEED = 0.75;
  int currentTime = 0;

  Size get screenSize => gameRef.screenSize;
  double get height => screenSize.height;
  double get width => screenSize.width;

  @override
  void resize(Size size) {
    x = size.width / 2;
    y = size.height / 2;
  }

  @override
  void render(Canvas c) {
    prepareCanvas(c);
    _drawBackground(c);
    _drawGamePlane(c, color: Palette.pink.color, stroke: 3, blendMode: BlendMode.srcOver);
    _drawGamePlane(c, color: Palette.white.color, stroke: 1, blendMode: BlendMode.lighten);
  }

  void _drawGamePlane(Canvas canvas, {Color color, double stroke, BlendMode blendMode}) {
    Paint linePaint = Paint()
      ..shader =
          ui.Gradient.linear(Offset(0, 0), Offset(width, height), [color, Palette.purple.color, color], [0, .6, 1])
      ..strokeWidth = stroke
      ..blendMode = blendMode;
    final lineSpacing = 60.0;
    final speedFactor = currentTime % (132 * FRICTION) / (160 * FRICTION);
    final movementAmount = (lineSpacing * speedFactor).floorToDouble();
    double lastLineY = height + movementAmount;
    final horizonY = height * .6;
    canvas.drawLine(Offset(0 - width, lastLineY), Offset(width + width, lastLineY), linePaint);
    while (lastLineY > horizonY * 1.04) {
      final factor = (lastLineY - horizonY) / horizonY;
      final lineY = lastLineY - lineSpacing * factor;
      canvas.drawLine(Offset(0 - width, lineY), Offset(width + width, lineY), linePaint);
      lastLineY = lineY;
    }

    final centerX = width / 2;
    canvas.drawLine(Offset(centerX, height), Offset(centerX, horizonY * 1.04), linePaint);
    for (int i = 1; i < 20; i++) {
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

  @override
  void update(double t) {
    super.update(t);
    currentTime += (t * 1000).toInt();
    angle = 0;
    /*angle += ROTATION_SPEED * t;
    angle %= 2 * math.pi;*/
  }

  @override
  void onMount() {
    width = height = gameRef.squareSize;
    anchor = Anchor.center;
  }
}
