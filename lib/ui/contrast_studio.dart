import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:giverny/experimental/contrast.dart';
import 'package:giverny/spaces/hct.dart';
import 'package:material_color_utilities/utils/color_utils.dart';
import 'package:material_color_utilities/utils/math_utils.dart';

import '../experimental/apca.dart';

class ContrastStudio extends StatefulWidget {
  const ContrastStudio({Key? key}) : super(key: key);

  @override
  _ContrastStudioState createState() => _ContrastStudioState();
}

class _ContrastStudioState extends State<ContrastStudio> {
  var _dp = 16.0;
  var _weight = 5;
  var _bgTone = 99.0;
  var _apcaEnabled = false;
  var _contrastRatioGoal = 4.5;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          children: [
            const SizedBox(
              height: 8,
            ),
            const SizedBox(
              height: 16,
            ),
            Text('Given', style: Theme.of(context).textTheme.headline6),
            if (_apcaEnabled) settings(context),
            if (!_apcaEnabled)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'contrast goal',
                    style: Theme.of(context).textTheme.caption,
                  ),
                  ...ContrastGoal.values.map(
                        (e) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Radio(
                            value: e.ratio,
                            groupValue: _contrastRatioGoal,
                            onChanged: (newValue) =>
                                setState(() { if (newValue is double) { _contrastRatioGoal = newValue; }}),
                          ),
                          Text(
                            e.text,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.caption,
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _bgToneSetting(context)),
            const SizedBox(
              height: 16,
            ),
            const SizedBox(
              height: 32,
            ),
            Text('Answer', style: Theme.of(context).textTheme.headline6),
            results(context),
            const Divider(),
            const SizedBox(
              height: 8,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Tooltip(
                  message:
                  'Enable UI for APCA, an exploration of a potential\nupdate to WCAG\'s contrast algorithm',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'APCA?',
                            style: Theme.of(context)
                                .textTheme
                                .subtitle1
                                ?.copyWith(fontFamily: 'GoogleSansMono'),
                          ),
                          Switch(
                              value: _apcaEnabled,
                              onChanged: (newValue) =>
                                  setState(() => _apcaEnabled = newValue))
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_apcaEnabled)
              OutlinedButton.icon(
                  onPressed: _showTldr,
                  icon: const Icon(Icons.help),
                  label: const Text('APCA TL;DR')),
          ],
        ),
      ),
    );
  }

  Future<void> _showTldr() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('APCA vs. WCAG contrast'),
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

  Widget _boundsVisualizer(
      double? lowerMin, double? higherMin, BuildContext context) {
    final children = <Widget>[];
    const width = 240.0;
    if (lowerMin != null && lowerMin >= 0) {
      children.add(Container(
        width: lowerMin / 100.0 * width,
        color: Colors.green,
      ));
    }
    if (higherMin != null && higherMin >= 0) {
      if (lowerMin != null && lowerMin >= 0) {
        children.add(Container(
          width: (higherMin - lowerMin) / 100.0 * width,
          color: Colors.red,
        ));
      } else {
        children.add(Container(
          width: (higherMin / 100.0) * width,
          color: Colors.red,
        ));
      }
      children.add(Container(
        width: width - (higherMin / 100.0 * width),
        color: Colors.green,
      ));
    } else {
      if (lowerMin != null && lowerMin >= 0) {
        children.add(Container(
          width: width - (lowerMin / 100.0 * width),
          color: Colors.red,
        ));
      } else {
        children.add(Container(
          width: width,
          color: Colors.red,
        ));
      }
    }
    return Container(
      width: width,
      height: 24,
      child: Row(children: children),
    );
  }

  Widget wcagPreview(BuildContext context) {
    final lighterWcag =
    Contrast.lighter(tone: _bgTone, contrastRatio: _dp < 40 ? 4.5 : 3.0);
    final darkerWcag =
    Contrast.darker(tone: _bgTone, contrastRatio: _dp < 40 ? 4.5 : 3.0);

    final children = <Widget>[];

    children.add(Tooltip(
      message: darkerWcag < 0
          ? 'darker color that meets contrast impossible'
          : 'T${darkerWcag.round()}',
      child: Container(
          color: Color(ColorUtils.argbFromLstar(_bgTone)),
          child: Padding(
              padding: const EdgeInsets.all(8),
              child: _weight < 10
                  ? Container(
                width: _dp,
                height: _dp,
                child: darkerWcag == -1
                    ? const Placeholder()
                    : Center(
                  child: Container(
                    child: Text(
                      'T',
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1
                          ?.copyWith(
                          height: 1.0,
                          fontSize: _dp,
                          color: Color(ColorUtils.argbFromLstar(
                              darkerWcag))),
                    ),
                  ),
                ),
              )
                  : Container(
                width: _dp,
                height: _dp,
                color: darkerWcag == -1
                    ? null
                    : Color(ColorUtils.argbFromLstar(darkerWcag)),
                child: darkerWcag == -1 ? const Placeholder() : null,
              ))),
    ));
    children.add(Container(
        color: Color(ColorUtils.argbFromLstar(_bgTone)),
        child: Padding(
            padding: const EdgeInsets.all(8),
            child: _weight < 10
                ? Container(
              width: _dp,
              height: _dp,
              child: lighterWcag < 0
                  ? const Placeholder()
                  : Center(
                child: Text(
                  'T',
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      ?.copyWith(
                      height: 1.0,
                      fontSize: _dp,
                      color: Color(ColorUtils.argbFromLstar(
                          lighterWcag))),
                ),
              ),
            )
                : Tooltip(
              message: lighterWcag < 0
                  ? 'lighter color that meets contrast impossible'
                  : 'T${lighterWcag.round()}',
              child: Container(
                width: _dp,
                height: _dp,
                color: lighterWcag == -1
                    ? null
                    : Color(ColorUtils.argbFromLstar(lighterWcag)),
                child: lighterWcag == -1 ? const Placeholder() : null,
              ),
            ))));
    return Row(
      children: children,
    );
  }

  Widget apcaPreview(BuildContext context) {
    final lighterApca = Apca.lighter(_bgTone, _dp, _weight);
    final darkerApca = Apca.darker(_bgTone, _dp, _weight);

    final children = <Widget>[];

    children.add(Container(
        color: Color(ColorUtils.argbFromLstar(_bgTone)),
        child: Padding(
            padding: const EdgeInsets.all(8),
            child: _weight < 10
                ? Container(
              width: _dp,
              height: _dp,
              child: darkerApca == null
                  ? const Placeholder()
                  : Center(
                child: Text(
                  'T',
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      ?.copyWith(
                      height: 1.0,
                      fontSize: _dp,
                      color: Color(ColorUtils.argbFromLstar(
                          darkerApca))),
                ),
              ),
            )
                : Container(
              width: _dp,
              height: _dp,
              color: darkerApca == null
                  ? null
                  : Color(ColorUtils.argbFromLstar(darkerApca)),
              child: darkerApca == null ? const Placeholder() : null,
            ))));
    children.add(Container(
      color: Color(ColorUtils.argbFromLstar(_bgTone)),
      child: Padding(
          padding: const EdgeInsets.all(8),
          child: _weight < 10
              ? Container(
            width: _dp,
            height: _dp,
            child: lighterApca == null
                ? const Placeholder()
                : Center(
              child: Text(
                'T',
                style: Theme.of(context)
                    .textTheme
                    .bodyText1
                    ?.copyWith(
                    fontSize: _dp,
                    height: 1.0,
                    color: Color(
                        ColorUtils.argbFromLstar(lighterApca))),
              ),
            ),
          )
              : Tooltip(
            message: lighterApca == null
                ? 'lighter color that meets contrast impossible'
                : 'T${lighterApca.round()}',
            child: Container(
              width: _dp,
              height: _dp,
              color: lighterApca == null
                  ? null
                  : Color(ColorUtils.argbFromLstar(lighterApca)),
              child: lighterApca == null ? const Placeholder() : null,
            ),
          )),
    ));
    return Row(
      children: children,
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
    - APCA is more relaxed for light solids
    - APCA is more constrained for dark solids
    - APCA is more constrained for small text (less than 12 pt)
    ''', style: Theme.of(context).textTheme.bodyText2),
        const SizedBox(
          height: 8,
        ),
        Text(
          'Why?',
          style: Theme.of(context).textTheme.headline6,
        ),
        Text('''
    - WCAG assumes everything is text
    - WCAG has only one input: whether the element is >= 18 pt/40 dp
    - APCA asks whether something is text or solid, and for the exact size
    - APCA has only one answer for solids, size does not matter
     ''', style: Theme.of(context).textTheme.bodyText2),
      ],
    );
  }

  Widget settings(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '${_dp.round().toString().padLeft(3)}dp/${(_dp * 72.0 / 160.0).round().toString().padLeft(3)}pt',
                style: Theme.of(context)
                    .textTheme
                    .subtitle1
                    ?.copyWith(fontFamily: 'GoogleSansMono'),
              ),
              Flexible(
                child: Column(
                  children: [
                    _sizeSetting(context),
                    if (!_apcaEnabled)
                      Text(
                        'only ≥40 dp matters',
                        style: Theme.of(context).textTheme.subtitle1?.copyWith(
                            fontFamily: 'GoogleSans',
                            fontSize: 12.0,
                            fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ),
              if (_apcaEnabled) _weightSetting(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bgToneSetting(BuildContext context) {
    return Row(
      children: [
        Text('need contrast with T${_bgTone.round().toString().padRight(3)}',
            style: Theme.of(context).textTheme.caption),
        Flexible(
          child: Slider(
            value: _bgTone,
            min: 0.0,
            max: 100.0,
            onChanged: (newValue) {
              setState(() {
                _bgTone = newValue;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _sizeSetting(BuildContext context) {
    return Slider(
      value: _dp,
      min: 16.0,
      max: 160,
      onChanged: (newValue) {
        setState(() {
          _dp = newValue;
        });
      },
    );
  }

  Widget _weightSetting(BuildContext context) {
    final captionStyle = Theme.of(context).textTheme.caption;
    return Tooltip(
      message:
      'Contrast changes with spatial frequency, or, whether it is text or a solid.\nWCAG does not account for this.\nAPCA recalculates based on text vs. solid, and the contrast requirement for solids is always the same. It does not change with size, but it should.',
      child: Row(
        children: [
          ToggleButtons(
              isSelected: [_weight == 5, _weight == 10],
              onPressed: (index) {
                setState(() {
                  if (index == 0) {
                    _weight = 5;
                  } else {
                    _weight = 10;
                  }
                });
              },
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.text_snippet_outlined),
                    Text('text', style: captionStyle),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.radio_button_unchecked),
                    Text('solid', style: captionStyle),
                  ],
                )
              ]),
        ],
      ),
    );
  }


  Widget results(BuildContext context) {
    final lighterApca = Apca.lighter(_bgTone, _dp, _weight);
    final darkerApca = Apca.darker(_bgTone, _dp, _weight);
    final lighterWcag = Contrast.lighter(
        tone: _bgTone,
        contrastRatio: !_apcaEnabled
            ? _contrastRatioGoal
            : _dp < 40
            ? 4.5
            : 3.0);
    final darkerWcag = Contrast.darker(
        tone: _bgTone,
        contrastRatio: !_apcaEnabled
            ? _contrastRatioGoal
            : _dp < 40
            ? 4.5
            : 3.0);
    final headerTextStyle = Theme.of(context)
        .textTheme
        .bodyText1
        ?.copyWith(fontFamily: 'GoogleSansMono');
    final apcaConstraintString =
    Contrast.constraintDescription(darkerApca, lighterApca);
    final wcagConstraintString =
    Contrast.constraintDescription(darkerWcag, lighterWcag);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_apcaEnabled)
          Tooltip(
            message:
            'APCA says $apcaConstraintString can be used on backgrounds of T${_bgTone.round()}',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'APCA',
                  style: headerTextStyle,
                ),
                const SizedBox(
                  width: 8,
                ),
                Column(
                  children: [
                    _boundsVisualizer(darkerApca, lighterApca, context),
                    Text(
                      apcaConstraintString,
                      style: headerTextStyle,
                    ),
                  ],
                ),
                apcaPreview(context),
              ],
            ),
          ),
        if (_apcaEnabled)
          const SizedBox(
            height: 8,
          ),
        Tooltip(
          message:
          'WCAG says $wcagConstraintString can be used on backgrounds of T${_bgTone.round()}',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_apcaEnabled)
                Text(
                  'WCAG',
                  style: headerTextStyle,
                ),
              const SizedBox(
                width: 8,
              ),
              Column(
                children: [
                  _boundsVisualizer(darkerWcag, lighterWcag, context),
                  Text(
                    wcagConstraintString,
                    style: headerTextStyle,
                  ),
                ],
              ),
              if (_apcaEnabled) wcagPreview(context),
            ],
          ),
        ),
      ],
    );
  }

}


enum ContrastGoal {
  three,
  fourFive,
  seven,
}

extension Helpers on ContrastGoal {
  double get ratio {
    switch (this) {
      case ContrastGoal.three:
        return 3.0;
      case ContrastGoal.fourFive:
        return 4.5;
      case ContrastGoal.seven:
        return 7.0;
    }
  }

  String get text {
    switch (this) {
      case ContrastGoal.three:
        return '3.0\n≥40 dp/18 pt';
      case ContrastGoal.fourFive:
        return '4.5\n<40 dp/18 pt';
      case ContrastGoal.seven:
        return '7.0\n≤20/80 vision';
    }
  }
}