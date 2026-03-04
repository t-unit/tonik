import 'dart:io';

/// Native implementation — reads the file synchronously.
List<int> readFileAsBytes(String path) => File(path).readAsBytesSync();
