import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/doc_comment_formatter.dart';

void generateLibraryFile({
  required ApiDocument apiDocument,
  required String outputDirectory,
  required String package,
}) {
  final packageDir = path.join(outputDirectory, package);
  final libDirPath = path.join(packageDir, 'lib');
  final libDir = Directory(libDirPath);
  final libraryFile = File(path.join(libDirPath, '$package.dart'));
  final srcDir = Directory(path.join(libDirPath, 'src'));

  // DEBUG LOGGING - REMOVE AFTER WINDOWS FIX
  print('[LibraryGenerator] outputDirectory: $outputDirectory');
  print('[LibraryGenerator] package: $package');
  print('[LibraryGenerator] packageDir: $packageDir');
  print('[LibraryGenerator] libDirPath: $libDirPath');
  print('[LibraryGenerator] libraryFile path: ${libraryFile.path}');
  print(
    '[LibraryGenerator] packageDir exists: ${Directory(packageDir).existsSync()}',
  );
  print(
    '[LibraryGenerator] libDir exists before create: ${libDir.existsSync()}',
  );

  final srcFiles = <String>[];
  if (srcDir.existsSync()) {
    srcFiles.addAll(
      srcDir
          .listSync(recursive: true)
          .where((entity) => entity is File && entity.path.endsWith('.dart'))
          .map((file) {
            // Extract the relative path from src directory
            final relativePath = path.relative(file.path, from: srcDir.path);
            return 'src/$relativePath';
          }),
    );
  }

  print('[LibraryGenerator] Found ${srcFiles.length} source files');

  srcFiles.sort();

  final docComments = _formatApiDocumentation(apiDocument);

  final buffer = StringBuffer()
    ..writeln('// Generated code - do not modify by hand')
    ..writeln('// ignore_for_file: lines_longer_than_80_chars')
    ..writeln()
    ..writeln();

  docComments.forEach(buffer.writeln);

  buffer
    ..writeln()
    ..writeln()
    ..writeln('library;')
    ..writeln();

  for (final file in srcFiles) {
    final normalizedPath = file.replaceAll(r'\\', '/');
    buffer.writeln("export '$normalizedPath';");
  }

  print('[LibraryGenerator] About to create lib directory...');
  if (!libDir.existsSync()) {
    print('[LibraryGenerator] lib directory does not exist, creating...');
    libDir.createSync(recursive: true);
    print(
      '[LibraryGenerator] Directory created, exists: ${libDir.existsSync()}',
    );
  } else {
    print('[LibraryGenerator] lib directory already exists');
  }

  print('[LibraryGenerator] About to write file: ${libraryFile.path}');
  print(
    '[LibraryGenerator] File exists before write: ${libraryFile.existsSync()}',
  );
  try {
    libraryFile.writeAsStringSync(buffer.toString());
    print('[LibraryGenerator] File written successfully');
    print(
      '[LibraryGenerator] File exists after write: ${libraryFile.existsSync()}',
    );
    print('[LibraryGenerator] File length: ${libraryFile.lengthSync()} bytes');
  } catch (e, stackTrace) {
    print('[LibraryGenerator] ERROR writing file: $e');
    print('[LibraryGenerator] Stack trace: $stackTrace');
    rethrow;
  }

  // List contents of lib directory
  if (libDir.existsSync()) {
    print('[LibraryGenerator] Contents of lib directory:');
    for (final entity in libDir.listSync()) {
      print(
        '[LibraryGenerator]   - ${entity.path} (${entity.statSync().type})',
      );
    }
  }
}

List<String> _formatApiDocumentation(ApiDocument apiDocument) {
  final lines = <String>[];

  if (apiDocument.title.isNotEmpty) {
    lines.add('/// ${apiDocument.title}');
  }

  if (apiDocument.version.isNotEmpty) {
    lines.add('/// Version ${apiDocument.version}');
  }

  if (apiDocument.summary != null && apiDocument.summary!.isNotEmpty) {
    lines.addAll(formatDocComment(apiDocument.summary));
  }

  if (apiDocument.description != null && apiDocument.description!.isNotEmpty) {
    lines.addAll(formatDocComment(apiDocument.description));
  }

  if (apiDocument.contact != null) {
    lines
      ..add('///')
      ..add('/// Contact: ${apiDocument.contact!.name ?? 'N/A'}');

    if (apiDocument.contact!.email != null) {
      lines.add('/// Email: ${apiDocument.contact!.email}');
    }

    if (apiDocument.contact!.url != null) {
      lines.add('/// URL: ${apiDocument.contact!.url}');
    }
  }

  if (apiDocument.license != null) {
    lines
      ..add('///')
      ..add('/// License: ${apiDocument.license!.name ?? 'N/A'}');

    if (apiDocument.license!.url != null) {
      lines.add('/// License URL: ${apiDocument.license!.url}');
    }

    if (apiDocument.license!.identifier != null) {
      lines.add('/// SPDX Identifier: ${apiDocument.license!.identifier}');
    }
  }

  if (apiDocument.termsOfService != null) {
    lines
      ..add('///')
      ..add('/// Terms of Service: ${apiDocument.termsOfService}');
  }

  if (apiDocument.externalDocs != null) {
    lines
      ..add('///')
      ..add(
        '/// Documentation: ${apiDocument.externalDocs!.description ?? 'N/A'}',
      );

    if (apiDocument.externalDocs!.url.isNotEmpty) {
      lines.add('/// Documentation URL: ${apiDocument.externalDocs!.url}');
    }
  }

  // Add security schemes information
  final securitySchemes = apiDocument.securitySchemes;
  if (securitySchemes.isNotEmpty) {
    lines
      ..add('///')
      ..add('/// Security Schemes:');

    for (final scheme in securitySchemes) {
      final schemeInfo = _formatSecurityScheme(scheme);
      lines.addAll(schemeInfo);
    }
  }

  return lines;
}

List<String> _formatSecurityScheme(SecurityScheme scheme) {
  final lines = <String>[];

  switch (scheme) {
    case ApiKeySecurityScheme():
      final location = switch (scheme.location) {
        ApiKeyLocation.header => 'header',
        ApiKeyLocation.query => 'query',
        ApiKeyLocation.cookie => 'cookie',
      };
      final description = (scheme.description?.isNotEmpty ?? false)
          ? ': ${scheme.description}'
          : '';
      lines.add('/// - API Key ($location)$description');

    case HttpSecurityScheme():
      final schemeName = switch (scheme.scheme.toLowerCase()) {
        'bearer' => 'Bearer',
        'basic' => 'Basic',
        _ => scheme.scheme.toUpperCase(),
      };
      final description = (scheme.description?.isNotEmpty ?? false)
          ? ': ${scheme.description}'
          : '';
      lines.add('/// - HTTP $schemeName$description');
      if (scheme.bearerFormat != null) {
        lines.add('///   Format: ${scheme.bearerFormat}');
      }

    case OAuth2SecurityScheme():
      final description = (scheme.description?.isNotEmpty ?? false)
          ? ': ${scheme.description}'
          : '';
      lines.add('/// - OAuth2$description');
      final flows = scheme.flows;

      if (flows.authorizationCode != null) {
        final flow = flows.authorizationCode!;
        lines
          ..add('///   Authorization URL: ${flow.authorizationUrl}')
          ..add('///   Token URL: ${flow.tokenUrl}');
        if (flow.scopes.isNotEmpty) {
          lines.add('///   Scopes: ${flow.scopes.keys.join(', ')}');
        }
      } else if (flows.implicit != null) {
        final flow = flows.implicit!;
        lines.add('///   Authorization URL: ${flow.authorizationUrl}');
        if (flow.scopes.isNotEmpty) {
          lines.add('///   Scopes: ${flow.scopes.keys.join(', ')}');
        }
      } else if (flows.clientCredentials != null) {
        final flow = flows.clientCredentials!;
        lines.add('///   Token URL: ${flow.tokenUrl}');
        if (flow.scopes.isNotEmpty) {
          lines.add('///   Scopes: ${flow.scopes.keys.join(', ')}');
        }
      } else if (flows.password != null) {
        final flow = flows.password!;
        lines.add('///   Token URL: ${flow.tokenUrl}');
        if (flow.scopes.isNotEmpty) {
          lines.add('///   Scopes: ${flow.scopes.keys.join(', ')}');
        }
      }

    case OpenIdConnectSecurityScheme():
      final description = (scheme.description?.isNotEmpty ?? false)
          ? ': ${scheme.description}'
          : '';
      lines.add('/// - OpenID Connect$description');
      lines.add('///   Discovery URL: ${scheme.openIdConnectUrl}');

    case MutualTlsSecurityScheme():
      final description = (scheme.description?.isNotEmpty ?? false)
          ? ': ${scheme.description}'
          : '';
      lines.add('/// - Mutual TLS$description');
  }

  return lines;
}
