import 'package:better_player_example/pages/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
      },
      child: MaterialApp(
        title: 'Better player demo',
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        debugShowCheckedModeBanner: false,
        debugShowMaterialGrid: false,
        showSemanticsDebugger: false,
        supportedLocales: [
          const Locale('en', 'US'),
          const Locale('pl', 'PL'),
        ],
        theme: ThemeData(
          primarySwatch: Colors.green,
        ),
        home: Navigator(
          onGenerateRoute: (settings) => MaterialPageRoute(
            builder: (context) => WelcomePage(),
          ),
        ),
      ),
    );
  }
}
