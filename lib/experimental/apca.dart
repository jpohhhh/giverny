import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../spaces/color_utils.dart';

class Apca {
  static const sRco = 0.2126729;
  static const sGco = 0.7151522;
  static const sBco = 0.0721750;
  static const mainTRC = 2.4;
  static const blkThrs = 0.022; // L* = 19.85
  static const blkClmp = 1.414;
  static const scaleWoB = 1.14;
  static const scaleBoW = 1.14;
  static const loBoWthresh = 0.035991;
  static const loWoBthresh = 0.035991;
  static const loBoWfactor = 27.7847239587675;
  static const loWoBfactor = 27.7847239587675;
  static const loBoWoffset = 0.027;
  static const loWoBoffset = 0.027;
  static const loClip = 0.001;
  static const deltaYmin = 0.0005; // L* = 0.61
  static const normBG = 0.56;
  static const normTXT = 0.57;
  static const revTXT = 0.62;
  static const revBG = 0.65;

  static double lc(double fgTone, double bgTone) {
    var fgY = ColorUtils.yFromLstar(fgTone) / 100.0;
    var bgY = ColorUtils.yFromLstar(bgTone) / 100.0;
    var sapc = 0.0;
    var outputContrast = 0.0;
    fgY = (fgY > blkThrs) ? fgY : fgY + math.pow(blkThrs - fgY, blkClmp);
    bgY = (bgY > blkThrs) ? bgY : bgY + math.pow(blkThrs - bgY, blkClmp);
    if ((bgY - fgY).abs() < deltaYmin) {
      return 0.0;
    }
    if (bgY > fgY) {
      sapc = (math.pow(bgY, normBG) - math.pow(fgY, normTXT)) * scaleBoW;
      outputContrast = (sapc < loClip)
          ? 0.0
          : (sapc < loBoWthresh)
          ? sapc - sapc * loBoWfactor * loBoWoffset
          : sapc - loBoWoffset;
    } else {
      sapc = (math.pow(bgY, revBG) - math.pow(fgY, revTXT)) * scaleWoB;
      outputContrast = (sapc > -loClip)
          ? 0.0
          : (sapc > -loWoBthresh)
          ? sapc - sapc * loWoBfactor * loWoBoffset
          : sapc + loWoBoffset;
    }
    return (outputContrast * 100.0).abs();
  }

  static double? lighter(double bgTone, double dp, int weight) {
    final minLc = requiredLc(dp, weight);
    if (minLc == null) {
      return null;
    }
    if (kDebugMode) {
      print(
        'lighter requires LC ${minLc.round()} for dp ${dp.round()} at weight $weight');
    }

    final maxLc = lc(100.0, bgTone);
    if (kDebugMode) {
      print('lighter maxLc = ${maxLc.round()} for bgTone ${bgTone.round()}');
    }
    if (maxLc < minLc) {
      return null;
    }

    for (var fgTone = bgTone; fgTone <= 100.0; fgTone++) {
      final achievedLc = lc(fgTone, bgTone);
      if (achievedLc >= minLc) {
        return fgTone;
      }
    }
    return null;
  }

  static double? darker(double bgTone, double dp, int weight) {
    final minLc = requiredLc(dp, weight);
    if (minLc == null) {
      return null;
    }
    final maxLc = lc(0.0, bgTone);
    if (maxLc < minLc) {
      return null;
    }

    for (var fgTone = bgTone; fgTone >= 0.0; fgTone = fgTone - 0.5) {
      final achievedLc = lc(fgTone, bgTone);
      if (achievedLc >= minLc) {
        return fgTone;
      }
    }
    return null;
  }

  static const largeCutoffDp = 40;

  /// Weight: 1 - 9 representing 100-900
  /// 160 dp in inch = 72 pt in inch
  /// 72/160 * dp = pt
  /// null returned if no contrast possible
  static double? requiredLc(double dp, int weight) {
    if (weight > 9) {
      return 30;
    }
    final pt = 72 / 160 * dp;

    if (pt < lcLut[0][0]!) {
      return null;
    }
    final lutRow = lcLut.firstWhere((element) => element[0]! >= pt);
    final index = weight + 1;
    final answer = lutRow[index];
    if (answer == null) {
      if (kDebugMode) {
        print(
          'required Lc for ${dp.round()} dp / ${pt.round()} pt at weight $weight = IMPOSSIBLE');
      }
    } else {
      if (kDebugMode) {
        print(
          'required Lc for ${dp.round()} dp / ${pt.round()} pt at weight $weight = ${answer.round()}');
      }
    }

    return answer;
  }

  // CSS pt, px, weights 100-900 required LC
  static final lcLut = <List<double?>>[
    [7.5, 10, null, null, null, 90, 85, 80, 75, null, null],
    [7.88, 10.5, null, null, null, 90, 85, 80, 75, null, null],
    [8.25, 11, null, null, null, 90, 85, 80, 75, null, null],
    [9, 12, null, null, 75, 90, 85, 80, 75, null, null],
    [10.5, 14, null, null, 75, 90, 85, 80, 75, null, null],
    [12, 16, null, 75, 75, 75, 70, 65, 60, 55, null],
    [13.5, 18, null, 75, 90, 70, 65, 60, 55, 50, 45],
    [15.8, 21, null, 75, 85, 65, 60, 55, 50, 45, 40],
    [18, 24, null, 90, 75, 60, 55, 50, 45, 40, 35],
    [24, 32, null, 85, 70, 55, 50, 45, 40, 35, 30],
    [31.5, 42, 90, 75, 60, 50, 45, 40, 35, 30, 30],
    [42, 56, 85, 70, 55, 45, 40, 35, 30, 30, 30],
    [54, 72, 75, 60, 50, 40, 35, 30, 30, 30, 30],
    [72, 96, 70, 55, 45, 35, 30, 30, 30, 30, 30],
    [96, 128, 60, 45, 40, 30, 30, 30, 30, 30, 30],
  ];
}
