import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';

String darkMapStyle(BuildContext context) {
  String hex(Color color) =>
      '#${(color.toARGB32() & 0xffffff).toRadixString(16).padLeft(6, '0')}';
  final colors = context.appColors;
  return jsonEncode([
    {
      'elementType': 'geometry',
      'stylers': [
        {'color': hex(colors.background)},
      ],
    },
    {
      'elementType': 'labels.text.fill',
      'stylers': [
        {'color': hex(Theme.of(context).colorScheme.onSurface)},
      ],
    },
    {
      'elementType': 'labels.text.stroke',
      'stylers': [
        {'color': hex(colors.background)},
      ],
    },
    {
      'featureType': 'road',
      'elementType': 'geometry',
      'stylers': [
        {'color': hex(colors.borderVariant)},
      ],
    },
    {
      'featureType': 'water',
      'elementType': 'geometry',
      'stylers': [
        {'color': hex(Theme.of(context).colorScheme.primaryContainer)},
      ],
    },
  ]);
}
