/// Web stub — file-system access is not available.
List<int> readFileAsBytes(String path) => throw UnsupportedError(
      'File path reading is not supported on web. '
      'Use TonikFileBytes instead of TonikFilePath.',
    );
