import 'package:flutter/material.dart';
import 'package:giverny/ui/root.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Giverny'),
        ),
        body: const RootWidget(),
      ),
    );
  }
}