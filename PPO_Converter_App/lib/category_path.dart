import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'api.dart';
import 'background.dart';
import 'category.dart';
import 'category_tile.dart';
import 'measure.dart';
import 'measure_converter.dart';

class CategoryRoute extends StatefulWidget {
  const CategoryRoute();

  @override
  _CategoryRouteState createState() => _CategoryRouteState();
}

class _CategoryRouteState extends State<CategoryRoute> {
  Category _defaultCategory;
  Category _currentCategory;
  final _categories = <Category>[];
  static const _baseColors = <ColorSwatch>[
    ColorSwatch(0xFF34378B, {
      'highlight': Color(0xFF34378B),
      'splash': Color(0xFF3C67D6),
    }),
    ColorSwatch(0xFFE495B2, {
      'highlight': Color(0xFFE495B2),
      'splash': Color(0xFFA35678),
    }),
    ColorSwatch(0xFFFBE5C6, {
      'highlight': Color(0xFFFBE5C6),
      'splash': Color(0xFFFFC77B),
      'error': Color(0xFF912D2D),
    }),
  ];


  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
    if (_categories.isEmpty) {
      await _retrieveLocalCategories();
      await _retrieveApiCategory();
    }
  }
  Future<void> _retrieveLocalCategories() async {
    final json = DefaultAssetBundle.of(context)
        .loadString('assets/data/regular_units.json');
    final data = JsonDecoder().convert(await json);
    if (data is! Map) {
      throw ('Data retrieved from API is not a Map');
    }
    var categoryIndex = 0;
    data.keys.forEach((key) {
      final List<Measure> measures =
          data[key].map<Measure>((dynamic data) => Measure.fromJson(data)).toList();

      var category = Category(
        name: key,
        measures: measures,
        color: _baseColors[categoryIndex],
      );
      setState(() {
        if (categoryIndex == 0) {
          _defaultCategory = category;
        }
        _categories.add(category);
      });
      categoryIndex += 1;
    });
  }


  Future<void> _retrieveApiCategory() async {
    setState(() {
      _categories.add(Category(
        name: apiCategory['name'],
        measures: [],
        color: _baseColors.last,
      ));
    });
    final api = Api();
    final jsonMeasures = await api.getMeasures(apiCategory['route']);
    if (jsonMeasures != null) {
      final measures = <Measure>[];
      for (var measure in jsonMeasures) {
        measures.add(Measure.fromJson(measure));
      }
      setState(() {
        _categories.removeLast();
        _categories.add(Category(
          name: apiCategory['name'],
          measures: measures,
          color: _baseColors.last,
        ));
      });
    }
  }

  void _onCategoryTap(Category category) {
    setState(() {
      _currentCategory = category;
    });
  }

  Widget _buildCategoryWidgets(Orientation deviceOrientation) {
    if (deviceOrientation == Orientation.portrait) {
      return ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          return CategoryTile(
            category: _categories[index],
            onTap: _onCategoryTap,
          );
        },
        itemCount: _categories.length,
      );
    } else {
      return GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 3.0,
        children: _categories.map((Category c) {
          return CategoryTile(
            category: c,
            onTap: _onCategoryTap,
          );
        }).toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_categories.isEmpty) {
      return Center(
        child: Container(
          height: 180.0,
          width: 180.0,
          child: CircularProgressIndicator(),
        ),
      );
    }

    assert(debugCheckHasMediaQuery(context));
    final listView = Padding(
      padding: EdgeInsets.only(
        left: 8.0,
        right: 8.0,
        bottom: 48.0,
      ),
      child: _buildCategoryWidgets(MediaQuery.of(context).orientation),
    );
    return Backdrop(
      currentCategory:
          _currentCategory == null ? _defaultCategory : _currentCategory,
      frontPanel: _currentCategory == null
          ? MeasureConverter(category: _defaultCategory)
          : MeasureConverter(category: _currentCategory),
      backPanel: listView,
      frontTitle: Text('Lab1_ConverterApp'),
      backTitle: Text('Выбрать другую категрию'),
    );
  }
}
