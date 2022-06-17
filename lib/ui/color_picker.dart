import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:giverny/experimental/contrast.dart';
import 'package:giverny/spaces/hct.dart';
import 'package:giverny/spaces/string_utils.dart';


class ColorPicker extends StatefulWidget {
  const ColorPicker(
      {Key? key,
      required this.onColor,
      required this.requested,
      this.showBackground = true,
      this.strict = true,
      this.width = 288.0,
      this.radius = 8.0})
      : super(key: key);

  final Function(Hct hct, Color sRgb) onColor;
  final Hct requested;
  final bool strict;
  final bool showBackground;
  final double width;
  final double radius;
  @override
  _ColorPickerState createState() => _ColorPickerState();

  static Hct generateRandomHct() {
    final random = Random();
    final hue = random.nextInt(360).toDouble();
    final chroma = random.nextInt(110).toDouble() + 10.0;
    final tone = random.nextInt(80).toDouble() + 10.0;
    final hct = Hct.from(hue, chroma, tone);
    return hct;
  }

  static Hct defaultValue() {
    return Hct.fromInt(0xff4285f4);
  }
}

class _ColorPickerState extends State<ColorPicker> {
  Hct get color => !widget.strict
      ? widget.requested
      : Hct.from(_hueStrict, _chromaStrict, _toneStrict);

  var _hueStrict = 0.0;
  var _chromaStrict = 0.0;
  var _toneStrict = 0.0;

  late TextEditingController _hueTextController;
  late TextEditingController _chromaTextController;
  late TextEditingController _toneTextController;
  late TextEditingController _hexTextController;

  @override
  void initState() {
    if (widget.requested != null) {
      _hueStrict = widget.requested.hue;
      _chromaStrict = widget.requested.chroma;
      _toneStrict = widget.requested.tone;
    } else {
      final strictHct = ColorPicker.defaultValue();
      _hueStrict = strictHct.hue;
      _chromaStrict = strictHct.chroma;
      _toneStrict = strictHct.tone;
    }

    _hueTextController =
        TextEditingController(text: color.hue.toStringAsFixed(0));
    _chromaTextController =
        TextEditingController(text: color.chroma.toStringAsFixed(0));
    _toneTextController =
        TextEditingController(text: color.tone.toStringAsFixed(0));
    _hexTextController =
        TextEditingController(text: StringUtils.hexFromArgb(color.toInt()));
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ColorPicker oldWidget) {
    if (oldWidget.requested != widget.requested && !widget.strict) {
      _hexTextController.value = _hueTextController.value
          .copyWith(text: StringUtils.hexFromArgb(color.toInt()));
      _hueTextController.value =
          _hueTextController.value.copyWith(text: color.hue.toStringAsFixed(0));
      _chromaTextController.value = _chromaTextController.value
          .copyWith(text: color.chroma.toStringAsFixed(0));
      _toneTextController.value = _toneTextController.value
          .copyWith(text: color.tone.toStringAsFixed(0));
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _hexTextController.dispose();
    _hueTextController.dispose();
    _chromaTextController.dispose();
    _toneTextController.dispose();
    super.dispose();
  }

  Color get textColor {
    return Contrast.textColor(color.tone);
  }

  TextStyle leadingTextStyle(BuildContext context) {
    final color = Contrast.textColor(widget.requested.tone);
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
          color: color,
        );
  }

  TextStyle entryTextStyle(BuildContext context) {
    final color = Contrast.textColor(widget.requested.tone);
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
          color: color,
        );
  }

  @override
  Widget build(BuildContext context) {
    final sliders = [
      buildHue(context),
      buildChroma(context),
      buildTone(context),
    ]
        .map((e) => SizedBox(
              height: 24,
              child: e,
            ))
        .toList();
    return Container(
      width: widget.width,
      decoration: !widget.showBackground
          ? null
          : BoxDecoration(
              color: Color(color.toInt()),
              border: Border.all(
                color: Color(color.toInt()).withOpacity(0.6),
              ),
              borderRadius: BorderRadius.all(Radius.circular(widget.radius))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ...sliders,
        Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            buildButtons(context),
            if (widget.strict)
              Column(
                children: [
                  Center(
                    child: Text(
                      Hct.from(_hueStrict, _chromaStrict, _toneStrict).toString(),
                      style: entryTextStyle(context),
                    ),
                  ),
                  OutlinedButton.icon(
                      onPressed: _showTldr,
                      icon: Icon(Icons.help, color:Contrast.textColor(widget.requested.tone) ,),
                      label:  Text('HCT?', style: entryTextStyle(context) )),
                ],
              ),
            _hexEditor(context),
          ],
        ),
        SizedBox(height: 32,),
        Text('colors with contrast ratio 3.0: ${Contrast.constraintDescription(Contrast.darker(tone: _toneStrict, contrastRatio: 3.0), Contrast.lighter(tone: _toneStrict, contrastRatio: 3.0))}'),
        Text('colors with contrast ratio 4.5: ${Contrast.constraintDescription(Contrast.darker(tone: _toneStrict, contrastRatio: 4.5), Contrast.lighter(tone: _toneStrict, contrastRatio: 4.5))}'),
        Text('colors with contrast ratio 7.0: ${Contrast.constraintDescription(Contrast.darker(tone: _toneStrict, contrastRatio: 7.0), Contrast.lighter(tone: _toneStrict, contrastRatio: 7.0))}'),
        OutlinedButton.icon(
            onPressed: _showContrastTldr,
            icon: Icon(Icons.help, color:Contrast.textColor(widget.requested.tone) ,),
            label:  Text('How is that calculated?', style: entryTextStyle(context) )),

      ]),
    );
  }


  Future<void> _showTldr() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('HCT'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                tldr(context),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Done'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  Future<void> _showContrastTldr() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Contrast'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                contrastTldr(context),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Done'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildButtons(BuildContext context) {
    final iconColor = Contrast.textColor(color.tone);
    const iconSize = 20.0;
    const buttonDimension = 28.0;
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Tooltip(
          message: 'Use a random color',
          child: SizedBox(
            height: buttonDimension,
            width: buttonDimension,
            child: IconButton(
              iconSize: iconSize,
              onPressed: () {
                final hct = ColorPicker.generateRandomHct();
                onChange(hue: hct.hue, chroma: hct.chroma, tone: hct.tone);
              },
              icon: Icon(
                Icons.shuffle,
                color: iconColor,
              ),
            ),
          ),
        ),
        Tooltip(
          message: 'Copy hex code',
          child: SizedBox(
            height: buttonDimension,
            width: buttonDimension,
            child: IconButton(
              iconSize: iconSize,
              onPressed: () async {
                final hex = StringUtils.hexFromArgb(color.toInt());
                await Clipboard.setData(ClipboardData(text: hex));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Copied $hex to Clipboard'),
                ));
              },
              icon: Icon(
                Icons.copy_outlined,
                color: iconColor,
              ),
            ),
          ),
        ),
        Tooltip(
          message: 'Paste hex code',
          child: SizedBox(
            height: buttonDimension,
            width: buttonDimension,
            child: IconButton(
              iconSize: iconSize,
              onPressed: () async {
                final data = await Clipboard.getData('text/plain');
                final text = data?.text;
                if (text == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: const Text('Paste failed; no text on Clipboard'),
                  ));
                  return;
                }
                final int = StringUtils.argbFromHex(text);
                if (int == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                      'Paste failed; couldn\'t parse \"${text.replaceAll('\n', '')}\" into hex code.',
                      maxLines: 1,
                    ),
                  ));
                  return;
                }
                final hct = Hct.fromInt(int);
                onChange(hue: hct.hue, chroma: hct.chroma, tone: hct.tone);
              },
              icon: Icon(
                Icons.paste_outlined,
                color: iconColor,
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget tldr(BuildContext context) {
    return Column(
      children: [
        Text(
          'TL;DR',
          style: Theme.of(context).textTheme.headline6,
        ),
        Text('''
    HCT, hue chroma tone, a color space that integrates contrast, enabling new frontiers in design.
    H and C are CAM16's hue and chroma, T is L*a*b*'s luminance.
    Not all HCTs have a corresponding RGB. HCT describes every possible color, RGB is limited to your display.
    The HCT you requested is on the right, the HCT you received is on the bottom, above the help button.
    When a requested HCT is impossible, chroma is reduced until it is possible. 
    ''', style: Theme.of(context).textTheme.bodyText2),
        Text(
          'Why?',
          style: Theme.of(context).textTheme.headline6,
        ),
        Text('''
    - design benefits from a color system that integrates and guarantees contrast
    - dynamic design requires such a color system
    - contrast is currently measured in a ratio using relative luminance (Y in XYZ)
    - relative luminance can be converted to a linear measure in perceptual luminance (L* in L*a*b*)
    - L*a*b* is extremely old, design found it inconsistent in ex. chroma across hues
    - by keying on maintaining luminance when gamut mapping, we can make any color system use L*
    - CAM16 is the most modern & widely accepted color system
    - HCT is CAM16 hue and chroma with L*a*b*'s L* lightness measure, gamut mapped to RGB by maintaining luminance
    ''', style: Theme.of(context).textTheme.bodyText2),
      ],
    );
  }


  Widget contrastTldr(BuildContext context) {
    return Column(
      children: [
        Text('''
    FOUNDATION:
    Luminance means lightness.
    Contrast ratio is measured using relative luminance. (Y in the XYZ color space).
    Y is a measure of photons, its scale of lightness doesn't match ours.
    L* is a measure of perceptual luminance, its scale of lightness matches ours.
    Y is trivially converted to L* in the L*a*b* color space.
    For any given color, we can find its Y, then use the contrast ratio equation to find the Y of contrasting colors, then convert that to L*.
    This lets us use contrast ratio as defined by WCAG, but have it be on an intuitive scale, a simple linear difference in L*.


    SIMPLE RULE:
    For any given L* in L*a*b*/T in HCT (i.e. luminance, from here, I'll say tone), the contrasting tones will be different.
    However, for all tones:
    - a tone delta of 38 guarantees a contrast ratio of 3.0.
    - a tone delta of 50 guarantees a contrast ratio of 4.5.
    "Tone delta of 40? 3.0. Tone delta of 50? 4.5." is often used to communicate this in a context that includes
    software engineers or designers, because it avoids long discussions about luminance and dependency on the exact input.


    EMPOWERS DESIGN AND A11Y:
    This also lets us empower design and a11y engineering.
    If colors are failing a contrast ratio test, one of them can have their L* changed to meet contrast.
    This empowers design because its very clear how to alter a color, and it matches ones aesthetic sense: hue and chroma are retained.
    This empowers a11y because its trivial to alter a color to meet user needs, in a way that design understands and respects.


    BACKWARDS AND FORWARD COMPATIBLE, or, WHY IS CONTRAST ONLY LUMINANCE??
    This is forward-compatible because there's no path to a contrast requirement not based in luminance.
    For a practical example, APCA, a nextgen proposal for WCAG contrast, is also based on luminance.

    Why does contrast only measure difference in luminance? We know colors also have hue and chroma.
    However, its impossible to tell the exact set of hues and chromas the user might not be able to see. 
    ~10% of the population is affected with a CVD, its unreasonable to have a contrast requirement that excludes them.
 
    Additionally, even for those with no CVD, luminance matters. Colors with the same luminance create a shimmering effect. 
    This is extremely well known in color science, to see it, try using two colors, one for background, one for text. 
    Both colors should have the same tone. You'll find the colors 'shimmer' and reading text in those conditions is quite frustrating.
    An example of this is yellow text (#ffff00) on a white (#ffffff) background.
    ''', style: Theme.of(context).textTheme.bodyText2),

      ],
    );
  }

  Widget _hexEditor(BuildContext context) {
    return SizedBox(
      width: 62,
      child: TextField(
        textAlign: TextAlign.center,
        controller: _hexTextController,
        decoration: InputDecoration(
            isCollapsed: true,
            fillColor: Color(widget.requested.toInt()),
            contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
            border: InputBorder.none),
        style: entryTextStyle(context)
            .copyWith(color: Contrast.textColor(widget.requested.tone)),
        onSubmitted: (newValue) {
          final text = newValue;
          if (text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Paste failed; no text on Clipboard'),
            ));
            return;
          }
          final int = StringUtils.argbFromHex(text);
          if (int == null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                'Paste failed; couldn\'t parse \"${text.replaceAll('\n', '')}\" into hex code.',
                maxLines: 1,
              ),
            ));
            return;
          }
          final hct = Hct.fromInt(int);
          onChange(hue: hct.hue, chroma: hct.chroma, tone: hct.tone);
        },
      ),
    );
  }

  Widget buildHue(BuildContext context) {
    final hueTrack = createTrack(SliderType.hue);
    return Row(
      children: [
        wrapInSliderTheme(
          track: hueTrack,
          child: Slider(
            value: widget.strict ? _hueStrict : color.hue,
            min: 0.0,
            max: 360.0,
            onChanged: (newValue) => onChange(hue: newValue),
          ),
        ),
        SizedBox(
          width: 48,
          child: TextField(
            textAlign: TextAlign.end,
            controller: _hueTextController,
            decoration: InputDecoration(
              filled: false,
              isCollapsed: true,
              prefix: Padding(
                padding: const EdgeInsets.fromLTRB(4.0, 2.0, 0.0, 2.0),
                child: Text(
                  'H',
                  style: leadingTextStyle(context),
                ),
              ),
              border: InputBorder.none,
            ),
            style: entryTextStyle(context),
            onSubmitted: (newValue) {
              final toDouble = double.tryParse(newValue);
              if (toDouble == null) {
                return;
              }
              if (toDouble.round() == widget.requested.hue.round()) {
                return;
              }
              onChange(hue: toDouble);
            },
          ),
        ),
      ],
    );
  }

  Widget buildChroma(BuildContext context) {
    final chromaTrack = createTrack(SliderType.chroma);
    return Row(
      children: [
        wrapInSliderTheme(
          track: chromaTrack,
          child: Slider(
            value: widget.strict ? _chromaStrict : color.chroma,
            min: 0.0,
            max: 120.0,
            onChanged: (newValue) => onChange(chroma: newValue),
          ),
        ),
        SizedBox(
          width: 48.0,
          child: TextField(
            textAlign: TextAlign.end,
            controller: _chromaTextController,
            style: entryTextStyle(context),
            decoration: InputDecoration(
              filled: false,
              isCollapsed: true,
              prefix: Padding(
                padding: const EdgeInsets.fromLTRB(4.0, 2.0, 0.0, 2.0),
                child: Text(
                  'C',
                  style: leadingTextStyle(context),
                ),
              ),
              border: InputBorder.none,
            ),
            onSubmitted: (newValue) {
              final toDouble = double.tryParse(newValue);
              if (toDouble == null) {
                return;
              }
              if (toDouble.round() == widget.requested.chroma.round()) {
                return;
              }
              onChange(chroma: toDouble);
            },
          ),
        ),
      ],
    );
  }

  Widget buildTone(BuildContext context) {
    final toneTrack = createTrack(SliderType.luminance);
    return Row(
      children: [
        wrapInSliderTheme(
          track: toneTrack,
          child: Slider(
            value: widget.strict ? _toneStrict : color.tone,
            min: 0.0,
            max: 100.0,
            onChanged: (newValue) => onChange(tone: newValue, hue: null),
          ),
        ),
        SizedBox(
          width: 48.0,
          child: TextField(
            textAlign: TextAlign.end,
            style: entryTextStyle(context),
            controller: _toneTextController,
            decoration: InputDecoration(
              filled: false,
              isCollapsed: true,
              prefix: Padding(
                padding: const EdgeInsets.fromLTRB(4.0, 2.0, 0.0, 2.0),
                child: Text(
                  'T',
                  style: leadingTextStyle(context),
                ),
              ),
              border: InputBorder.none,
            ),
            onSubmitted: (newValue) {
              final toDouble = double.tryParse(newValue);
              if (toDouble == null) {
                return;
              }
              if (toDouble.round() == widget.requested.tone.round()) {
                return;
              }
              onChange(tone: toDouble);
            },
          ),
        ),
      ],
    );
  }

  SliderTrackShape createTrack(SliderType type) {
    return RetroSliderTrackShape(type, color.hue, color.chroma, color.tone);
  }

  void onChange({double? hue, double? chroma, double? tone}) {
    _hueStrict = hue ?? _hueStrict;
    _chromaStrict = chroma ?? _chromaStrict;
    _toneStrict = tone ?? _toneStrict;
    if (widget.strict) {
      _hueTextController.value = _hueTextController.value
          .copyWith(text: _hueStrict.toStringAsFixed(0));
      _chromaTextController.value = _chromaTextController.value
          .copyWith(text: _chromaStrict.toStringAsFixed(0));
      _toneTextController.value = _toneTextController.value
          .copyWith(text: _toneStrict.toStringAsFixed(0));
      _hexTextController =
          TextEditingController(text: StringUtils.hexFromArgb(color.toInt()));
    }

    hue ??= color.hue;
    chroma ??= color.chroma;
    tone ??= color.tone;
    final actual = Hct.from(hue, chroma, tone);
    final rgb = actual.toInt();
    widget.onColor(actual, Color(rgb));
  }

  Widget wrapInSliderTheme({
    required SliderTrackShape track,
    required Widget child,
  }) {
    return Expanded(
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackShape: track,
          trackHeight: 24.0,
          thumbShape: CustomSliderThumbC(
            passingContrastRatio: true,
            thumbRadius: 8,
            context: context,
          ),
        ),
        child: child,
      ),
    );
  }
}

class CustomSliderThumbC extends SliderComponentShape {
  final bool passingContrastRatio;
  final double thumbRadius;
  final int min;
  final int max;
  final BuildContext context;

  const CustomSliderThumbC({
    required this.context,
    required this.passingContrastRatio,
    required this.thumbRadius,
    this.min = 0,
    this.max = 10,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  String getValue(double value) {
    return (min + (max - min) * value).round().toString();
  }

  @override
  void paint(PaintingContext context, Offset center,
      {required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextPainter labelPainter,
      required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required double value,
      required double textScaleFactor,
      required Size sizeWithOverflow}) {
    final canvas = context.canvas;

    final paint = Paint()
      ..color = passingContrastRatio
          ? Theme.of(this.context).colorScheme.onSurface
          : Colors.red //Thumb Background Color
      ..style = PaintingStyle.fill
      ..strokeWidth = 1.0;

    const top = 0.0;
    final bottom = parentBox.size.height;
    canvas.drawLine(Offset(center.dx, top), Offset(center.dx, bottom), paint);
  }
}



enum SliderType {
  hue,
  chroma,
  luminance,
}
// ignore_for_file: slash_for_doc_comments, omit_local_variable_types,  prefer_single_quotes, annotate_overrides

class RetroSliderTrackShape extends SliderTrackShape {
  final SliderType type;
  final double hue;
  final double chroma;
  final double tone;

  late List<Color> colors;

  RetroSliderTrackShape(this.type, this.hue, this.chroma, this.tone) {
    switch (type) {
      case SliderType.chroma:
        colors = interpolateInChroma();
        break;
      case SliderType.hue:
        colors = interpolateInHue();
        break;
      case SliderType.luminance:
        colors = interpolateInLuminance();
        break;
    }
  }



  List<Color> interpolateInHue() {
    return List.generate(
        360,
            (index) =>
            Color(Hct.from(index.toDouble(), chroma, tone).toInt()));
  }

  List<Color> interpolateInChroma() {
    const resolution = 1.0;
    return List.generate((130.0 / resolution).round(), (index) {
      final chroma = index * resolution;
      final hct = Hct.from(hue, chroma, tone);
      return Color(hct.toInt());
    });
  }

  List<Color> interpolateInLuminance() {
    const resolution = 1.0;
    return List.generate(
      (100.0 / resolution).round(),
          (index) => Color(
        Hct.from(hue, chroma, index * resolution).toInt(),
      ),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset, {required RenderBox parentBox, required SliderThemeData sliderTheme, required Animation<double> enableAnimation, required Offset thumbCenter, bool isEnabled = true, bool isDiscrete = false, required TextDirection textDirection}) {
    if (sliderTheme.trackHeight == 0) {
      return;
    }
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final expectedColorCount = colors.length;
    final actualColorCount = colors.length;
    final apparentEndRight =
        actualColorCount / expectedColorCount * trackRect.right;
    final actualEndRight = trackRect.right;
    final stops = List<double>.generate(
        colors.length,
            (index) =>
        trackRect.right /
            colors.length *
            index /
            trackRect.right *
            (apparentEndRight / actualEndRight));

    final fillPaint = Paint();
    int index = 0;
    for (var stop in stops) {
      fillPaint.color = colors[index++];
      final pathSegment = Path()
        ..addRect(Rect.fromLTWH(stop * trackRect.width, trackRect.top,
            trackRect.width - (stop * trackRect.width), trackRect.height));
      context.canvas.drawPath(pathSegment, fillPaint);
    }  }

  @override
  Rect getPreferredRect({required RenderBox parentBox, Offset offset = Offset.zero, required SliderThemeData sliderTheme, bool isEnabled = true, bool isDiscrete = false}) {
    final double thumbWidth =
        sliderTheme.thumbShape!.getPreferredSize(true, isDiscrete).width;

    final double trackHeight = sliderTheme.trackHeight!;

    assert(thumbWidth >= 0);

    assert(trackHeight >= 0);

    assert(parentBox.size.width >= thumbWidth);

    assert(parentBox.size.height >= trackHeight);

    final double trackLeft = offset.dx;

    final double trackTop = (parentBox.size.height - trackHeight) / 2.0;

    final double trackWidth = parentBox.size.width;

    final rect = Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
    return rect;
  }
}
