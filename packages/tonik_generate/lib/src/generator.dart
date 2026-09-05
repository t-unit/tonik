import 'dart:io';

import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/analysis_options_generator.dart';
import 'package:tonik_generate/src/api_client/api_client_file_generator.dart';
import 'package:tonik_generate/src/api_client/api_client_generator.dart';
import 'package:tonik_generate/src/library_generator.dart';
import 'package:tonik_generate/src/model/all_of_generator.dart';
import 'package:tonik_generate/src/model/any_of_generator.dart';
import 'package:tonik_generate/src/model/class_generator.dart';
import 'package:tonik_generate/src/model/enum_generator.dart';
import 'package:tonik_generate/src/model/model_file_generator.dart';
import 'package:tonik_generate/src/model/one_of_generator.dart';
import 'package:tonik_generate/src/model/typedef_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/operation/operation_base_file_generator.dart';
import 'package:tonik_generate/src/operation/operation_file_generator.dart';
import 'package:tonik_generate/src/operation/operation_generator.dart';
import 'package:tonik_generate/src/pubspec_generator.dart';
import 'package:tonik_generate/src/request/request_body_file_generator.dart';
import 'package:tonik_generate/src/request/request_body_generator.dart';
import 'package:tonik_generate/src/response/response_file_generator.dart';
import 'package:tonik_generate/src/response/response_generator.dart';
import 'package:tonik_generate/src/response_wrapper/response_wrapper_file_generator.dart';
import 'package:tonik_generate/src/response_wrapper/response_wrapper_generator.dart';
import 'package:tonik_generate/src/server/server_file_generator.dart';
import 'package:tonik_generate/src/server/server_generator.dart';
import 'package:tonik_generate/src/transport/transport_backend_generator_factory.dart';
import 'package:tonik_generate/src/util/model_worker_pool.dart';
import 'package:tonik_generate/src/util/operation_parameter_defaults.dart';

class Generator {
  const Generator();

  /// Below this model count, isolate setup outweighs the parallel speedup.
  static const int parallelThreshold = 200;

  static int resolveWorkerCount(int requested) {
    if (requested == 0) {
      return clampAutoWorkerCount(Platform.numberOfProcessors);
    }
    return requested;
  }

  /// Reserves one processor for main; gains flatten above 16 on every spec
  /// benchmarked.
  static int clampAutoWorkerCount(int processorCount) {
    return (processorCount - 1).clamp(1, 16);
  }

  Future<void> generate({
    required ApiDocument apiDocument,
    required String outputDirectory,
    required String package,
    TonikConfig config = const TonikConfig(),
    @visibleForTesting ModelWorkerPool Function()? workerPoolFactory,
  }) async {
    final backendGenerator = transportBackendGeneratorFor(
      config.transport.backend,
    );
    final publicArtifacts = <String>{};

    final useImmutableCollections = config.useImmutableCollections;

    final nameGenerator = NameGenerator();
    final stableModelSorter = StableModelSorter();
    final nameManager = NameManager(
      generator: nameGenerator,
      stableModelSorter: stableModelSorter,
    );

    final classGenerator = ClassGenerator(
      nameManager: nameManager,
      package: package,
      useImmutableCollections: useImmutableCollections,
    );
    final enumGenerator = EnumGenerator(nameManager: nameManager);
    final oneOfGenerator = OneOfGenerator(
      nameManager: nameManager,
      package: package,
      stableModelSorter: stableModelSorter,
      useImmutableCollections: useImmutableCollections,
    );
    final anyOfGenerator = AnyOfGenerator(
      nameManager: nameManager,
      package: package,
      stableModelSorter: stableModelSorter,
      useImmutableCollections: useImmutableCollections,
    );
    final typedefGenerator = TypedefGenerator(
      nameManager: nameManager,
      package: package,
      useImmutableCollections: useImmutableCollections,
    );
    final allOfGenerator = AllOfGenerator(
      nameManager: nameManager,
      package: package,
      stableModelSorter: stableModelSorter,
      useImmutableCollections: useImmutableCollections,
    );

    final modelGenerator = ModelFileGenerator(
      classGenerator: classGenerator,
      enumGenerator: enumGenerator,
      anyOfGenerator: anyOfGenerator,
      oneOfGenerator: oneOfGenerator,
      typedefGenerator: typedefGenerator,
      allOfGenerator: allOfGenerator,
    );

    final defaultsCache = OperationDefaultsCache(
      nameManager: nameManager,
      package: package,
    );

    final operationGenerator = OperationGenerator(
      nameManager: nameManager,
      package: package,
      defaultsCache: defaultsCache,
      backendGenerator: backendGenerator,
      useImmutableCollections: useImmutableCollections,
    );

    final operationFileGenerator = OperationFileGenerator(
      operationGenerator: operationGenerator,
    );
    final operationBaseFileGenerator = OperationBaseFileGenerator(
      operationBaseGenerator: backendGenerator.operationBaseGenerator,
      nameManager: nameManager,
    );

    final requestBodyGenerator = RequestBodyGenerator(
      nameManager: nameManager,
      package: package,
      useImmutableCollections: useImmutableCollections,
    );

    final requestBodyFileGenerator = RequestBodyFileGenerator(
      requestBodyGenerator: requestBodyGenerator,
      classGenerator: classGenerator,
    );

    final responseGenerator = ResponseGenerator(
      nameManager: nameManager,
      package: package,
      useImmutableCollections: useImmutableCollections,
    );

    final responseFileGenerator = ResponseFileGenerator(
      responseGenerator: responseGenerator,
    );

    final responseWrapperGenerator = ResponseWrapperGenerator(
      nameManager: nameManager,
      package: package,
      useImmutableCollections: useImmutableCollections,
    );

    final responseWrapperFileGenerator = ResponseWrapperFileGenerator(
      responseWrapperGenerator: responseWrapperGenerator,
    );

    final apiClientGenerator = ApiClientGenerator(
      nameManager: nameManager,
      package: package,
      defaultsCache: defaultsCache,
      backendGenerator: backendGenerator,
      useImmutableCollections: useImmutableCollections,
    );

    final apiClientFileGenerator = ApiClientFileGenerator(
      apiClientGenerator: apiClientGenerator,
    );

    final serverGenerator = ServerGenerator(
      nameManager: nameManager,
      backendGenerator: backendGenerator,
    );

    final serverFileGenerator = ServerFileGenerator(
      serverGenerator: serverGenerator,
    );

    nameManager.prime(
      models: apiDocument.models,
      responses: apiDocument.responses,
      requestBodies: apiDocument.requestBodies,
      operations: apiDocument.operations,
      tags: apiDocument.operationsByTag.keys,
      servers: apiDocument.servers,
    );

    generatePubspec(
      apiDocument: apiDocument,
      outputDirectory: outputDirectory,
      package: package,
      backendGenerator: backendGenerator,
      useImmutableCollections: useImmutableCollections,
    );
    generateAnalysisOptions(outputDirectory: outputDirectory, package: package);

    final List<String> modelFiles;
    final resolvedWorkerCount = resolveWorkerCount(config.workerCount);
    if (resolvedWorkerCount == 1 ||
        apiDocument.models.length < parallelThreshold) {
      modelFiles = modelGenerator.writeFiles(
        apiDocument: apiDocument,
        outputDirectory: outputDirectory,
        package: package,
      );
    } else {
      final pool = (workerPoolFactory ?? ModelWorkerPool.new)();
      modelFiles = await pool.run(
        apiDocument: apiDocument,
        nameManager: nameManager,
        stableModelSorter: stableModelSorter,
        outputDirectory: outputDirectory,
        package: package,
        useImmutableCollections: useImmutableCollections,
        workerCount: resolvedWorkerCount,
      );
    }
    publicArtifacts.addAll(modelFiles);

    final requestBodyFiles = requestBodyFileGenerator.writeFiles(
      apiDocument: apiDocument,
      outputDirectory: outputDirectory,
      package: package,
      excludeSchemas: config.filter.excludeSchemas,
      deprecatedSchemas: config.deprecated.schemas,
    );
    publicArtifacts.addAll(requestBodyFiles);

    final responseFiles = responseFileGenerator.writeFiles(
      apiDocument: apiDocument,
      outputDirectory: outputDirectory,
      package: package,
    );
    publicArtifacts.addAll(responseFiles);

    final responseWrapperFiles = responseWrapperFileGenerator.writeFiles(
      apiDocument: apiDocument,
      outputDirectory: outputDirectory,
      package: package,
    );
    publicArtifacts.addAll(responseWrapperFiles);

    operationBaseFileGenerator.writeFile(
      outputDirectory: outputDirectory,
      package: package,
    );

    operationFileGenerator.writeFiles(
      apiDocument: apiDocument,
      outputDirectory: outputDirectory,
      package: package,
    );

    final apiClientFiles = apiClientFileGenerator.writeFiles(
      apiDocument: apiDocument,
      outputDirectory: outputDirectory,
      package: package,
    );
    publicArtifacts.addAll(apiClientFiles);

    final serverFile = serverFileGenerator.writeFiles(
      apiDocument: apiDocument,
      outputDirectory: outputDirectory,
      package: package,
    );
    publicArtifacts.add(serverFile);

    generateLibraryFile(
      apiDocument: apiDocument,
      outputDirectory: outputDirectory,
      package: package,
      publicArtifacts: publicArtifacts,
    );
  }
}
