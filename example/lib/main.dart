import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:math_expressions/math_expressions.dart';

void main() {
  runApp(const ExampleApp());
}

/// Example app demonstrating how to use the `math_keyboard` package.
class ExampleApp extends StatelessWidget {
  /// Creates an [ExampleApp] widget.
  const ExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math Keyboard Demo',
      supportedLocales: const [
        Locale('en', 'US'),
        // Providing another supported locale ("de_DE" in this case) allows
        // switching the locale on the emulator (for example) and then seeing
        // a different decimal separator. Only locales that are declared in the
        // supportedLocales will be returned by Localizations.localeOf.
        // So if you want to prevent commas as decimal separators, you should
        // not provide supported locales that use commas as decimal separators.
        Locale('de', 'DE'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
      ],
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DemoPage(),
    );
  }
}

/// Widget for a page demonstrating how to use the `math_keyboard` package.
class DemoPage extends StatefulWidget {
  /// Creates a [DemoPage] widget.
  const DemoPage({Key? key}) : super(key: key);

  @override
  _DemoPageState createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  var _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_currentIndex == 0) {
      child = const _MathFieldTextFieldExample();
    } else if (_currentIndex == 1) {
      child = const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'The math keyboard should be automatically dismissed when '
            'switching to this page.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      child = const _ClearableAutofocusExample();
    }

    return MathKeyboardViewInsets(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Math keyboard demo'),
        ),
        body: Column(
          children: [
            Expanded(
              child: child,
            ),
            // We insert the bottom navigation bar here instead of the
            // bottomNavigationBar parameter in order to make it stick on
            // top of the keyboard.
            BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  label: 'Fields',
                  icon: Icon(Icons.text_fields_outlined),
                ),
                BottomNavigationBarItem(
                  label: 'Empty',
                  icon: Icon(Icons.hourglass_empty_outlined),
                ),
                BottomNavigationBarItem(
                  label: 'Calculator',
                  icon: Icon(Icons.auto_awesome),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget that displays an example column with different math fields and a text
/// field for comparison.
class _MathFieldTextFieldExample extends StatelessWidget {
  /// Constructs a [_MathFieldTextFieldExample] widget.
  const _MathFieldTextFieldExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: TextField(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: MathField(
              variables: const ['a', 's', 'c'],
              onChanged: (value) {
                String expression;
                try {
                  expression = '${TeXParser(value).parse()}';
                } catch (_) {
                  expression = 'invalid input';
                }

                print('input expression: $value\n'
                    'converted expression: $expression');
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: MathField(
              keyboardType: MathKeyboardType.numberOnly,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget for an example math field in a column that can be cleared from the
/// outside and automatically receives focus.
class _ClearableAutofocusExample extends StatefulWidget {
  /// Constructs a [_ClearableAutofocusExample] widget.
  const _ClearableAutofocusExample({Key? key}) : super(key: key);

  @override
  _ClearableAutofocusExampleState createState() => _ClearableAutofocusExampleState();
}

class _ClearableAutofocusExampleState extends State<_ClearableAutofocusExample> {
  late final _controller = MathFieldEditingController();
  String _result = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double paddingPixels = 14;
    var textStyle = TextStyle(color: Colors.blueGrey, fontStyle: FontStyle.normal, fontSize: 32);
    return SafeArea(
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(paddingPixels),
            child: MathField(
              keyboardType: MathKeyboardType.calculator,
              controller: _controller,
              onSubmitted: (value) {},
              onChanged: (value) {
                if (value == '\\Box') {
                  _result = '';
                } else {
                  try {
                    double tmpResult = TeXParser(value).parse().evaluate(EvaluationType.REAL, ContextModel());
                    if (value.endsWith('??C') || value.endsWith('??F')) {
                      _result = tmpResult.toStringAsFixed(2);
                    } else {
                      _result = tmpResult.toStringAsFixed(14);
                    }
                  } catch (_) {
                    _result = 'invalid input';
                  }
                  if (_result.contains('.')) {
                    while (_result.endsWith('0')) {
                      _result = _result.substring(0, _result.length - 1);
                    }
                    if (_result.endsWith('.')) {
                      _result = _result.substring(0, _result.length - 1);
                    }
                  }

                  if (value.endsWith('??C')) {
                    _result += '??F';
                  } else if (value.endsWith('??F')) {
                    _result += '??C';
                  }
                }
                setState(() {});
              },
              decoration: InputDecoration(
                suffix: MouseRegion(
                  cursor: MaterialStateMouseCursor.clickable,
                  child: GestureDetector(
                    onTap: _controller.clear,
                    child: const Icon(
                      Icons.highlight_remove,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.only(left: paddingPixels),
                    minimumSize: Size.zero,
                  ),
                  onPressed: () {},
                  child: Text(_result.isEmpty ? ' ' : '=', style: textStyle)),
              TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.only(left: 5),
                    minimumSize: Size.zero,
                  ),
                  onPressed: () {},
                  child: Text(_result, style: textStyle)),
            ],
          ),
        ],
      ),
    );
  }
}
