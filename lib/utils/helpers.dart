
import 'package:flutter/material.dart';

int _columnsForWidth(BuildContext context) {
  final w = MediaQuery.of(context).size.width;
  // min tile width ~ 300
  final cols = (w / 300).floor();
  return cols.clamp(1, 6);
}

void globalfunction() {
  print("Dies ist eine globale Funktion!");
}