import 'package:flutter/material.dart';
import 'package:giverny/spaces/hct.dart';
import 'package:giverny/ui/color_picker.dart';

class ColorStudio extends StatefulWidget {
  const ColorStudio({Key? key}) : super(key: key);

  @override
  State<ColorStudio> createState() => _ColorStudioState();
}

class _ColorStudioState extends State<ColorStudio> {
  var _hct = Hct.fromInt(0xff4285f4);
  
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: kThemeAnimationDuration,
        color: Color(_hct.toInt()),
        child: Center(
          child: ColorPicker(showBackground: false, requested: _hct, onColor: (hct, color) {
            setState(() {
              _hct = hct;
            });
          },),
        ),
      ),
    );
  }
}
