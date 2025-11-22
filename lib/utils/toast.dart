import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

void showToast(String msg, {bool isError = false}) {
  Fluttertoast.showToast(
    msg: msg,
    toastLength: Toast.LENGTH_LONG,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: isError ? Colors.red : Colors.green,
    textColor: Colors.white,
    fontSize: 16,
  );
}