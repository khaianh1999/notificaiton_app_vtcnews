import 'package:flutter/material.dart';

class KTextStyle {
  static const TextStyle titleTealText = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.teal,
  );
  static const TextStyle descriptionTealText = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.teal,
  );
}

// Lúc nào dùng thì viết
// style : KTextStyle.titleTealText
// style : KTextStyle.descriptionTealText
// style : KTextStyle.titleTealText.copyWith(fontSize: 20)
