import 'package:flutter/material.dart';
import 'package:giverny/ui/contrast_studio.dart';

import 'color_studio.dart';

class RootWidget extends StatefulWidget {
  const RootWidget({Key? key}) : super(key: key);

  @override
  State<RootWidget> createState() => _RootWidgetState();
}

class _RootWidgetState extends State<RootWidget> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        NavigationRail(selectedIndex: _index, destinations: const [
          NavigationRailDestination(icon: Icon(Icons.palette), label: Text('HCT')),
          NavigationRailDestination(icon: Icon(Icons.contrast), label: Text('Contrast')),
        ], onDestinationSelected: (index) {
          setState(() {
            _index = index;
          });
        },),
        if (_index == 0) const ColorStudio(),
        if (_index == 1) ContrastStudio(),
      ],
    );
  }
}
