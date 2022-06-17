import 'dart:math' as math;

import 'package:giverny/spaces/color_utils.dart';
import 'package:giverny/spaces/hct.dart';
import 'package:giverny/spaces/math_utils.dart';

List<double> bruteForceLumasAtTone(double tone) {
  var min = 100.0;
  var max = 0.0;
  for (var h = 0.0; h < 360.0; h += 1.0) {
    final hct = Hct.from(h, 120.0, tone);
    final argb = hct.toInt();
    final luma = lumaFromArgb(argb);
    min = math.min(luma, min);
    max = math.max(luma, max);
  }
  return [min, max];
}

double lumaFromTone(double tone) {
  final argb = ColorUtils.argbFromLstar(tone);
  return lumaFromArgb(argb);
}

double lumaFromArgb(int argb) {
  final red = ColorUtils.redFromArgb(argb) / 255;
  final green = ColorUtils.greenFromArgb(argb) / 255;
  final blue = ColorUtils.blueFromArgb(argb) / 255;
  return 0.2126 * red + 0.7152 * green + 0.0722 * blue;
}

int darkestArgbForLuma(double luma) {
  // first use as much blue as possible
  var lumaRemaining = luma;
  final blue = MathUtils.clampDouble(
    0.0,
    1.0,
    lumaRemaining / 0.0722,
  );
  lumaRemaining = lumaRemaining - 0.0722 * blue;
  final red = MathUtils.clampDouble(0.0, 1.0, lumaRemaining / 0.2126);
  lumaRemaining = lumaRemaining - 0.2126 * red;
  final green = MathUtils.clampDouble(0.0, 1.0, lumaRemaining / 0.7152);
  lumaRemaining = lumaRemaining - 0.7152 * green;

  final argb = ColorUtils.argbFromRgb(
      (red * 255).floor(), (green * 255).floor(), (blue * 255).floor());

  return argb;
}

int lightestArgbForLuma(double luma) {
  // first use as much blue as possible
  var lumaRemaining = luma;
  final green = MathUtils.clampDouble(0.0, 1.0, lumaRemaining / 0.7152);
  lumaRemaining = lumaRemaining - 0.7152 * green;
  final red = MathUtils.clampDouble(0.0, 1.0, lumaRemaining / 0.2126);
  lumaRemaining = lumaRemaining - 0.2126 * red;
  final blue = MathUtils.clampDouble(0.0, 1.0, lumaRemaining / 0.0722);
  lumaRemaining = lumaRemaining - 0.0722 * blue;
  final argb = ColorUtils.argbFromRgb(
      (red * 255).floor(), (green * 255).floor(), (blue * 255).floor());
  return argb;
}
