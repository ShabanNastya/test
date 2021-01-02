import 'dart:async';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import 'api.dart';
import 'category.dart';
import 'measure.dart';

const _padding = EdgeInsets.all(16.0);


class MeasureConverter extends StatefulWidget {
  final Category category;

  /// This [MeasureConverter] takes in a [Category] with [Measure]. It can't be null.
  const MeasureConverter({
    @required this.category,
  }) : assert(category != null);

  @override
  _MeasureConverterState createState() => _MeasureConverterState();
}

class _MeasureConverterState extends State<MeasureConverter> {
  Measure _fromValue;
  Measure _toValue;
  double _inputValue;
  String _convertedValue = '';
  List<DropdownMenuItem> _measureMenuItems;
  bool _showValidationError = false;
  final _inputKey = GlobalKey(debugLabel: 'inputText');
  bool _showErrorUI = false;

  @override
  void initState() {
    super.initState();
    _createDropdownMenuItems();
    _setDefaults();
  }

  @override
  void didUpdateWidget(MeasureConverter old) {
    super.didUpdateWidget(old);
    if (old.category != widget.category) {
      _createDropdownMenuItems();
      _setDefaults();
    }
  }


  void _createDropdownMenuItems() {
    var newItems = <DropdownMenuItem>[];
    for (var measure in widget.category.measures) {
      newItems.add(DropdownMenuItem(
        value: measure.name,
        child: Container(
          child: Text(
            measure.name,
            softWrap: true,
          ),
        ),
      ));
    }
    setState(() {
      _measureMenuItems = newItems;
    });
  }


  void _setDefaults() {
    setState(() {
      _fromValue = widget.category.measures[0];
      _toValue = widget.category.measures[1];
    });
    if (_inputValue != null) {
      _updateConversion();
    }
  }

  /// Clean up conversion; trim trailing zeros, e.g. 5.500 -> 5.5, 10.0 -> 10
  String _format(double conversion) {
    var outputNum = conversion.toStringAsPrecision(7);
    if (outputNum.contains('.') && outputNum.endsWith('0')) {
      var i = outputNum.length - 1;
      while (outputNum[i] == '0') {
        i -= 1;
      }
      outputNum = outputNum.substring(0, i + 1);
    }
    if (outputNum.endsWith('.')) {
      return outputNum.substring(0, outputNum.length - 1);
    }
    return outputNum;
  }

  Future<void> _updateConversion() async {
    // Our API has a handy convert function, so we can use that for
    // the Currency [Category]
    if (widget.category.name == apiCategory['name']) {
      final api = Api();
      final conversion = await api.convert(apiCategory['route'],
          _inputValue.toString(), _fromValue.name, _toValue.name);
      // API error or not connected to the internet
      if (conversion == null) {
        setState(() {
          _showErrorUI = true;
        });
      } else {
        setState(() {
          _showErrorUI = false;
          _convertedValue = _format(conversion);
        });
      }
    } else {
      setState(() {
        _convertedValue = _format(
            _inputValue * (_toValue.conversion / _fromValue.conversion));
      });
    }
  }

  void _updateInputValue(String input) {
    setState(() {
      if (input == null || input.isEmpty) {
        _convertedValue = '';
      } else {
        try {
          final inputDouble = double.parse(input);
          _showValidationError = false;
          _inputValue = inputDouble;
          _updateConversion();
        } on Exception catch (e) {
          print('Ошибка: $e');
          _showValidationError = true;
        }
      }
    });
  }

  Measure _getMeasure(String measureName) {
    return widget.category.measures.firstWhere(
          (Measure measure) {
        return measure.name == measureName;
      },
      orElse: null,
    );
  }

  void _updateFromConversion(dynamic measureName) {
    setState(() {
      _fromValue = _getMeasure(measureName);
    });
    if (_inputValue != null) {
      _updateConversion();
    }
  }

  void _updateToConversion(dynamic measureName) {
    setState(() {
      _toValue = _getMeasure(measureName);
    });
    if (_inputValue != null) {
      _updateConversion();
    }
  }

  Widget _createDropdown(String currentValue, ValueChanged<dynamic> onChanged) {
    return Container(
      margin: EdgeInsets.only(top: 16.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(
          color: Colors.grey[400],
          width: 1.0,
        ),
      ),
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.grey[50],
        ),
        child: DropdownButtonHideUnderline(
          child: ButtonTheme(
            alignedDropdown: true,
            child: DropdownButton(
              value: currentValue,
              items: _measureMenuItems,
              onChanged: onChanged,
              style: Theme.of(context).textTheme.subtitle1,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.category.measures == null ||
        (widget.category.name == apiCategory['name'] && _showErrorUI)) {
      return SingleChildScrollView(
        child: Container(
          margin: _padding,
          padding: _padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            color: widget.category.color['error'],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Извините, сейчас это не сработает",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.subtitle1.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final input = Padding(
      padding: _padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: _inputKey,
            style: Theme.of(context).textTheme.subtitle1,
            decoration: InputDecoration(
              labelStyle: Theme.of(context).textTheme.subtitle1,
              errorText: _showValidationError ? 'Неправильный ввод!' : null,
              labelText: 'Ввод...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(0.0),
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: _updateInputValue,
          ),
          _createDropdown(_fromValue.name, _updateFromConversion),
        ],
      ),
    );

    final arrows = RotatedBox(
      quarterTurns: 1,
    );

    final output = Padding(
      padding: _padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InputDecorator(
            child: Text(
              _convertedValue,
              style: Theme.of(context).textTheme.subtitle1,
            ),
            decoration: InputDecoration(
              labelText: 'Вывод...',
              labelStyle: Theme.of(context).textTheme.subtitle1,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(0.0),
              ),
            ),
          ),
          _createDropdown(_toValue.name, _updateToConversion),
        ],
      ),
    );

    final converter = ListView(
      children: [
        input,
        arrows,
        output,
      ],
    );

    return Padding(
      padding: _padding,
      child: OrientationBuilder(
        builder: (BuildContext context, Orientation orientation) {
          if (orientation == Orientation.portrait) {
            return converter;
          } else {
            return Center(
              child: Container(
                width: 450.0,
                child: converter,
              ),
            );
          }
        },
      ),
    );
  }
}