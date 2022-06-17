

import 'package:flutter/material.dart';
import 'package:giverny/spaces/color_utils.dart';
import 'dart:math' as math;

import 'package:giverny/spaces/hct.dart';

class Contrast {
  static bool isLight(double tone) {
    return tone.round() > 49.0;
  }

  static bool isDark(double tone) {
    return !isLight(tone);
  }

  static Color textColor(double backgroundTone) {
    return isLight(backgroundTone) ? Colors.black : Colors.white;
  }

  static Color contrastingColor(
      Hct hctToContrastWith, Hct hctToTweak, double contrastRatio) {
    if (((hctToContrastWith.hue - 27.0).abs() < 8.0) &&
        hctToContrastWith.chroma > 40.0 &&
        hctToContrastWith.tone < 70.0) {
      return Colors.white;
    }
    if (contrastOfTones(hctToContrastWith.tone, hctToTweak.tone) >=
        contrastRatio) {
      return Color(hctToTweak.toInt());
    }

    final hct =
    Hct.from(hctToTweak.hue, hctToTweak.chroma, hctToTweak.tone);
    hct.tone = isLight(hctToContrastWith.tone)
        ? darkerUnsafe(
        tone: hctToContrastWith.tone, contrastRatio: contrastRatio)
        : lighterUnsafe(
        tone: hctToContrastWith.tone, contrastRatio: contrastRatio);
    return Color(hct.toInt());
  }

  static Color properTextColor(Hct hct) {
    if (((hct.hue - 27.0).abs() < 8.0) && hct.chroma > 40.0) {
      return Colors.white;
    }
    return isLight(hct.tone) ? Colors.black : Colors.white;
  }

  static double lighterUnsafe({required double tone, required double contrastRatio}) {
    final lighterSafe = lighter(tone: tone, contrastRatio: contrastRatio);
    return (lighterSafe == -1) ? 100.0 : lighterSafe;
  }

  static double darkerUnsafe({required double tone, required double contrastRatio}) {
    final darkerSafe = darker(tone: tone, contrastRatio: contrastRatio);
    return (darkerSafe == -1) ? 0.0 : darkerSafe;
  }

  static String contrastConstraintDescription(
      {required double tone, required double contrastRatio}) {
    final darkerTone =
    Contrast.darker(tone: tone, contrastRatio: contrastRatio);
    final lighterTone =
    Contrast.lighter(tone: tone, contrastRatio: contrastRatio);
    var string = '';
    if (darkerTone != -1) {
      if (darkerTone.floor() == 0) {
        string += '=${darkerTone.floor()}';
      } else {
        string += '≤${darkerTone.ceil()}';
      }
    }
    if (lighterTone != -1) {
      if (string.isNotEmpty) {
        string += ' or T';
      }
      string += '≥${lighterTone.ceil()}';
    }
    if (string.isEmpty) {
      string =
      ': none, cannot contrast with any other colors at contrast ratio ${contrastRatio.toStringAsFixed(1)}';
    }
    return string;
  }

  static String constraintDescription(double? darkerTone, double? lighterTone) {
    var string = '';
    if (darkerTone != -1) {
      if (darkerTone?.floor() == 0) {
        string += 'T=${darkerTone?.floor()}';
      } else {
        string += 'T≤${darkerTone?.ceil()}';
      }
    }
    if (lighterTone != -1) {
      if (string.isNotEmpty) {
        string += ' & T';
      } else {
        string += 'T';
      }
      string += '≥${lighterTone?.ceil()}';
    }
    if (string.isEmpty) {
      string = 'impossible';
    }
    return string;
  }

  static double lighter({required double tone, required double contrastRatio}) {
    final darkY = ColorUtils.yFromLstar(tone);
    final lightY = contrastRatio * (darkY + 5.0) - 5.0;
    final realContrast = contrastFromYs(lightY, darkY);
    final delta = (realContrast - contrastRatio).abs();
    if (realContrast < contrastRatio && delta > 0.04) {
      return -1;
    }

    final returnValue = lstarFromY(lightY) + 0.01;
    if (returnValue < 0 || returnValue > 100) {
      return -1;
    }
    return returnValue;
  }

  static double darker({required double tone, required double contrastRatio}) {
    final lightY = ColorUtils.yFromLstar(tone);
    final darkY = ((lightY + 5.0) / contrastRatio) - 5.0;
    final realContrast = contrastFromYs(lightY, darkY);

    final delta = (realContrast - contrastRatio).abs();
    if (realContrast < contrastRatio && delta > 0.04) {
      return -1;
    }

    final returnValue = lstarFromY(darkY) - 0.01;
    if (returnValue < 0 || returnValue > 100) {
      return -1;
    }
    return returnValue;
  }

  static double contrastOfTones(double t1, double t2) {
    return contrastFromYs(ColorUtils.yFromLstar(t1), ColorUtils.yFromLstar(t2));
  }

  static double ofArgbs(int one, int two) {
    return contrastOfTones(
        ColorUtils.lstarFromArgb(one), ColorUtils.lstarFromArgb(two));
  }

  static double contrastFromYs(double y1, double y2) {
    final lighter = y1 > y2 ? y1 : y2;
    final darker = (lighter == y2) ? y1 : y2;
    return (lighter + 5.0) / (darker + 5.0);
  }

  static double lstarFromY(double y) {
    const e = 216.0 / 24389.0;
    const kappa = 24389.0 / 27.0;

    final yNormalized = y / ColorUtils.whitePointD65()[1];
    double fy;
    if (yNormalized > e) {
      fy = math.pow(yNormalized, 1.0 / 3.0).toDouble();
    } else {
      fy = (kappa * yNormalized + 16) / 116;
    }

    final l = 116.0 * fy - 16;
    return l;
  }
}
