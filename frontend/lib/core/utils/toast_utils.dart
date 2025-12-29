import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ToastUtils {
  static Future<bool?> showShort(String message) {
    return _showToast(message, Toast.LENGTH_SHORT);
  }

  static Future<bool?> showLong(String message) {
    return _showToast(message, Toast.LENGTH_LONG);
  }

  static Future<bool?> _showToast(String message, Toast toastLength) {
    return Fluttertoast.showToast(
      msg: message,
      toastLength: toastLength,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }
}
