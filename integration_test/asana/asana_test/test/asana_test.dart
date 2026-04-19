import 'package:asana_api/asana_api.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}/api/1.0';
  });

  // ── Helper ───────────────────────────────────────────────────────────

  /// Creates a [Dio] instance for direct operation usage.
  Dio buildDio({required String responseStatus}) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {'X-Response-Status': responseStatus},
      ),
    );
  }

  // ── GET /workspaces (GetWorkspaces) ──────────────────────────────────

  group('GetWorkspaces', () {
    test('get_workspaces 200', () async {
      final op = GetWorkspaces(buildDio(responseStatus: '200'));

      final result = await op();

      expect(result, isA<TonikSuccess<GetWorkspacesResponse>>());
      final success = result as TonikSuccess<GetWorkspacesResponse>;
      expect(success.response.statusCode, 200);
      expect(
        success.value,
        isA<GetWorkspacesResponse200>(),
      );

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/api/1.0/workspaces');
    });

    test('get_workspaces 401', () async {
      final op = GetWorkspaces(buildDio(responseStatus: '401'));

      final result = await op();

      expect(result, isA<TonikSuccess<GetWorkspacesResponse>>());
      final success = result as TonikSuccess<GetWorkspacesResponse>;
      expect(success.response.statusCode, 401);
      expect(
        success.value,
        isA<GetWorkspacesResponse401>(),
      );
    });
  });

  // ── GET /workspaces/{workspaceGid} (GetWorkspace) ────────────────────

  group('GetWorkspace', () {
    test('get_workspace 200', () async {
      final op = GetWorkspace(buildDio(responseStatus: '200'));

      final result = await op(workspaceGid: '12345');

      expect(
        result,
        isA<TonikSuccess<GetWorkspaceResponse>>(),
      );
      final success = result as TonikSuccess<GetWorkspaceResponse>;
      expect(success.response.statusCode, 200);
      expect(
        success.value,
        isA<GetWorkspaceResponse200>(),
      );

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/api/1.0/workspaces/12345');
    });
  });

  // ── GET /users (GetUsers) ────────────────────────────────────────────

  group('GetUsers', () {
    test('get_users 200', () async {
      final op = GetUsers(buildDio(responseStatus: '200'));

      final result = await op(workspace: 'ws-123');

      expect(result, isA<TonikSuccess<GetUsersResponse>>());
      final success = result as TonikSuccess<GetUsersResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetUsersResponse200>());

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/api/1.0/users');
      expect(
        uri.queryParameters['workspace'],
        'ws-123',
      );
    });
  });

  // ── GET /tasks/{taskGid} (GetTask) ───────────────────────────────────

  group('GetTask', () {
    test('get_task 200', () async {
      final op = GetTask(buildDio(responseStatus: '200'));

      final result = await op(taskGid: '11111');

      expect(result, isA<TonikSuccess<GetTaskResponse>>());
      final success = result as TonikSuccess<GetTaskResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetTaskResponse200>());

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/api/1.0/tasks/11111');
    });

    test('get_task 404', () async {
      final op = GetTask(buildDio(responseStatus: '404'));

      final result = await op(taskGid: 'nonexistent');

      expect(result, isA<TonikSuccess<GetTaskResponse>>());
      final success = result as TonikSuccess<GetTaskResponse>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<GetTaskResponse404>());
    });
  });

  // ── GET /projects/{projectGid} (GetProject) ──────────────────────────

  group('GetProject', () {
    test('get_project 200', () async {
      final op = GetProject(buildDio(responseStatus: '200'));

      final result = await op(projectGid: '22222');

      expect(
        result,
        isA<TonikSuccess<GetProjectResponse>>(),
      );
      final success = result as TonikSuccess<GetProjectResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetProjectResponse200>());

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/api/1.0/projects/22222');
    });
  });

  // ── GET /projects/{projectGid}/tasks (GetTasksForProject) ────────────

  group('GetTasksForProject', () {
    test('get_tasks_for_project 200', () async {
      final op = GetTasksForProject(
        buildDio(responseStatus: '200'),
      );

      final result = await op(
        projectGid: '22222',
        limit: 10,
      );

      expect(
        result,
        isA<TonikSuccess<GetTasksForProjectResponse>>(),
      );
      final success = result as TonikSuccess<GetTasksForProjectResponse>;
      expect(success.response.statusCode, 200);
      expect(
        success.value,
        isA<GetTasksForProjectResponse200>(),
      );

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/api/1.0/projects/22222/tasks');
      expect(uri.queryParameters['limit'], '10');
    });
  });

  // ── POST /tasks (CreateTask) ─────────────────────────────────────────

  group('CreateTask', () {
    test('create_task 201', () async {
      final op = CreateTask(buildDio(responseStatus: '201'));

      final result = await op(
        body: const TasksPostBodyBodyModel(
          data: TaskRequest(
            taskBase: TaskBase(
              taskCompact: TaskCompact(name: 'New Task'),
              taskBaseModel: TaskBaseModel(),
            ),
            taskRequestModel: TaskRequestModel(
              workspace: '12345',
            ),
          ),
        ),
      );

      expect(
        result,
        isA<TonikSuccess<CreateTaskResponse>>(),
      );
      final success = result as TonikSuccess<CreateTaskResponse>;
      expect(success.response.statusCode, 201);
      expect(
        success.value,
        isA<CreateTaskResponse201>(),
      );

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/api/1.0/tasks');
    });
  });

  // ── POST /workspaces/{workspaceGid}/projects ─────────────────────────

  group('CreateProjectForWorkspace', () {
    test('create_project_for_workspace 201', () async {
      final op = CreateProjectForWorkspace(
        buildDio(responseStatus: '201'),
      );

      final result = await op(
        workspaceGid: '12345',
        body: const WorkspacesWorkspaceGidProjectsPostBodyBodyModel(
          data: ProjectRequest(
            projectBase: ProjectBase(
              projectCompact: ProjectCompact(
                name: 'New Project',
              ),
              projectBaseModel: ProjectBaseModel(),
            ),
            projectRequestModel: ProjectRequestModel(),
          ),
        ),
      );

      expect(
        result,
        isA<TonikSuccess<CreateProjectForWorkspaceResponse>>(),
      );
      final success = result as TonikSuccess<CreateProjectForWorkspaceResponse>;
      expect(success.response.statusCode, 201);
      expect(
        success.value,
        isA<CreateProjectForWorkspaceResponse201>(),
      );

      final uri = success.response.requestOptions.uri;
      expect(
        uri.path,
        '/api/1.0/workspaces/12345/projects',
      );
    });
  });

  // ── PUT /tasks/{taskGid} (UpdateTask) ────────────────────────────────

  group('UpdateTask', () {
    test('update_task 200', () async {
      final op = UpdateTask(buildDio(responseStatus: '200'));

      final result = await op(
        taskGid: '11111',
        body: const TasksTaskGidPutBodyBodyModel(
          data: TaskRequest(
            taskBase: TaskBase(
              taskCompact: TaskCompact(
                name: 'Updated Task',
              ),
              taskBaseModel: TaskBaseModel(),
            ),
            taskRequestModel: TaskRequestModel(),
          ),
        ),
      );

      expect(
        result,
        isA<TonikSuccess<UpdateTaskResponse>>(),
      );
      final success = result as TonikSuccess<UpdateTaskResponse>;
      expect(success.response.statusCode, 200);
      expect(
        success.value,
        isA<UpdateTaskResponse200>(),
      );

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/api/1.0/tasks/11111');
      expect(
        success.response.requestOptions.method,
        'PUT',
      );
    });
  });

  // ── DELETE /tasks/{taskGid} (DeleteTask) ─────────────────────────────

  group('DeleteTask', () {
    test('delete_task 200', () async {
      final op = DeleteTask(buildDio(responseStatus: '200'));

      final result = await op(taskGid: '11111');

      expect(
        result,
        isA<TonikSuccess<DeleteTaskResponse>>(),
      );
      final success = result as TonikSuccess<DeleteTaskResponse>;
      expect(success.response.statusCode, 200);
      expect(
        success.value,
        isA<DeleteTaskResponse200>(),
      );

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/api/1.0/tasks/11111');
      expect(
        success.response.requestOptions.method,
        'DELETE',
      );
    });
  });
}
