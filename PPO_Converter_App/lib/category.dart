import 'package:flutter/cupertino.dart';
import 'package:meta/meta.dart';
import 'measure.dart';
import 'package:flutter/material.dart';

class Category {
  final String name;
  final ColorSwatch color;
  final List<Measure> measures;

  const Category({
    @required this.name,
    @required this.color,
    @required this.measures,
  })  : assert(name != null),
        assert(color != null),
        assert(measures != null);
}
