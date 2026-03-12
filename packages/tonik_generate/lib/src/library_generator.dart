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
    final normalizedPath = file.replaceAll(r'\', '/');
    buffer.writeln("export '$normalizedPath';");
  }

  if (!libDir.existsSync()) {
    libDir.createSync(recursive: true);
  }
  libraryFile.writeAsStringSync(buffer.toString());
}

List<String> _formatApiDocumentation(ApiDocument apiDocument) {
  final lines = <String>[];

  if (apiDocument.title.isNotEmpty) {
    lines.addAll(formatDocComment(apiDocument.title));
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
      ..addAll(
        formatDocCommentWithPrefix(
          'Contact: ',
          apiDocument.contact!.name ?? 'N/A',
        ),
      );

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
      ..addAll(
        formatDocCommentWithPrefix(
          'License: ',
          apiDocument.license!.name ?? 'N/A',
        ),
      );

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
      ..addAll(
        formatDocCommentWithPrefix(
          'Terms of Service: ',
          apiDocument.termsOfService,
        ),
      );
  }

  if (apiDocument.externalDocs != null) {
    lines
      ..add('///')
      ..addAll(
        formatDocCommentWithPrefix(
          'Documentation: ',
          apiDocument.externalDocs!.description ?? 'N/A',
        ),
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
      if (scheme.description != null && scheme.description!.isNotEmpty) {
        lines.addAll(
          formatDocCommentWithPrefix(
            '- API Key ($location): ',
            scheme.description,
          ),
        );
      } else {
        lines.add('/// - API Key ($location)');
      }

    case HttpSecurityScheme():
      final schemeName = switch (scheme.scheme.toLowerCase()) {
        'bearer' => 'Bearer',
        'basic' => 'Basic',
        _ => scheme.scheme.toUpperCase(),
      };
      if (scheme.description != null && scheme.description!.isNotEmpty) {
        lines.addAll(
          formatDocCommentWithPrefix(
            '- HTTP $schemeName: ',
            scheme.description,
          ),
        );
      } else {
        lines.add('/// - HTTP $schemeName');
      }
      if (scheme.bearerFormat != null) {
        lines.add('///   Format: ${scheme.bearerFormat}');
      }

    case OAuth2SecurityScheme():
      if (scheme.description != null && scheme.description!.isNotEmpty) {
        lines.addAll(
          formatDocCommentWithPrefix('- OAuth2: ', scheme.description),
        );
      } else {
        lines.add('/// - OAuth2');
      }
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
      if (scheme.description != null && scheme.description!.isNotEmpty) {
        lines.addAll(
          formatDocCommentWithPrefix(
            '- OpenID Connect: ',
            scheme.description,
          ),
        );
      } else {
        lines.add('/// - OpenID Connect');
      }
      lines.add('///   Discovery URL: ${scheme.openIdConnectUrl}');

    case MutualTlsSecurityScheme():
      if (scheme.description != null && scheme.description!.isNotEmpty) {
        lines.addAll(
          formatDocCommentWithPrefix('- Mutual TLS: ', scheme.description),
        );
      } else {
        lines.add('/// - Mutual TLS');
      }
  }

  return lines;
}
