import 'package:asana_api/asana_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}/api/1.0';
  });

  // ── Helper ───────────────────────────────────────────────────────────

  CustomServer buildServer({required String responseStatus}) {
    return CustomServer(
      baseUrl: baseUrl,
      serverConfig: testServerConfig(
        headers: {'X-Response-Status': responseStatus},
      ),
    );
  }

  // ── GET /workspaces (GetWorkspaces) ──────────────────────────────────

  group('GetWorkspaces', () {
    test('get_workspaces 200', () async {
      final api = WorkspacesApi(buildServer(responseStatus: '200'));

      final result = await api.getWorkspaces();

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetWorkspacesResponse200>());
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/api/1.0/workspaces');
    });

    test('get_workspaces 401', () async {
      final api = WorkspacesApi(buildServer(responseStatus: '401'));

      final result = await api.getWorkspaces();

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 401);
      expect(success.value, isA<GetWorkspacesResponse401>());
    });
  });

  // ── GET /workspaces/{workspaceGid} (GetWorkspace) ────────────────────

  group('GetWorkspace', () {
    test('get_workspace 200', () async {
      final api = WorkspacesApi(buildServer(responseStatus: '200'));

      final result = await api.getWorkspace(workspaceGid: '12345');

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetWorkspaceResponse200>());
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/api/1.0/workspaces/12345');
    });
  });

  // ── GET /users (GetUsers) ────────────────────────────────────────────

  group('GetUsers', () {
    test('get_users 200', () async {
      final api = UsersApi(buildServer(responseStatus: '200'));

      final result = await api.getUsers(workspace: 'ws-123');

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetUsersResponse200>());
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/api/1.0/users');
      expect(uri.queryParameters['workspace'], 'ws-123');
    });
  });

  // ── GET /tasks/{taskGid} (GetTask) ───────────────────────────────────

  group('GetTask', () {
    test('get_task 200', () async {
      final api = TasksApi(buildServer(responseStatus: '200'));

      final result = await api.getTask(taskGid: '11111');

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetTaskResponse200>());
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/api/1.0/tasks/11111');
    });

    test('get_task 404', () async {
      final api = TasksApi(buildServer(responseStatus: '404'));

      final result = await api.getTask(taskGid: 'nonexistent');

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 404);
      expect(success.value, isA<GetTaskResponse404>());
    });
  });

  // ── GET /projects/{projectGid} (GetProject) ──────────────────────────

  group('GetProject', () {
    test('get_project 200', () async {
      final api = ProjectsApi(buildServer(responseStatus: '200'));

      final result = await api.getProject(projectGid: '22222');

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetProjectResponse200>());
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/api/1.0/projects/22222');
    });
  });

  // ── GET /projects/{projectGid}/tasks (GetTasksForProject) ────────────

  group('GetTasksForProject', () {
    test('get_tasks_for_project 200', () async {
      final api = TasksApi(buildServer(responseStatus: '200'));

      final result = await api.getTasksForProject(
        projectGid: '22222',
        limit: 10,
      );

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetTasksForProjectResponse200>());
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/api/1.0/projects/22222/tasks');
      expect(uri.queryParameters['limit'], '10');
    });
  });

  // ── POST /tasks (CreateTask) ─────────────────────────────────────────

  group('CreateTask', () {
    test('create_task 201', () async {
      final api = TasksApi(buildServer(responseStatus: '201'));

      final result = await api.createTask(
        body: const TasksPostBodyBodyModel(
          data: TaskRequest(
            taskBase: TaskBase(
              taskCompact: TaskCompact(name: 'New Task'),
              taskBaseModel: TaskBaseModel(),
            ),
            taskRequestModel: TaskRequestModel(workspace: '12345'),
          ),
        ),
      );

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 201);
      expect(success.value, isA<CreateTaskResponse201>());
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/api/1.0/tasks');
    });
  });

  // ── POST /workspaces/{workspaceGid}/projects ─────────────────────────

  group('CreateProjectForWorkspace', () {
    test('create_project_for_workspace 201', () async {
      final api = ProjectsApi(buildServer(responseStatus: '201'));

      final result = await api.createProjectForWorkspace(
        workspaceGid: '12345',
        body: const WorkspacesWorkspaceGidProjectsPostBodyBodyModel(
          data: ProjectRequest(
            projectBase: ProjectBase(
              projectCompact: ProjectCompact(name: 'New Project'),
              projectBaseModel: ProjectBaseModel(),
            ),
            projectRequestModel: ProjectRequestModel(),
          ),
        ),
      );

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 201);
      expect(success.value, isA<CreateProjectForWorkspaceResponse201>());
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/api/1.0/workspaces/12345/projects');
    });
  });

  // ── PUT /tasks/{taskGid} (UpdateTask) ────────────────────────────────

  group('UpdateTask', () {
    test('update_task 200', () async {
      final api = TasksApi(buildServer(responseStatus: '200'));

      final result = await api.updateTask(
        taskGid: '11111',
        body: const TasksTaskGidPutBodyBodyModel(
          data: TaskRequest(
            taskBase: TaskBase(
              taskCompact: TaskCompact(name: 'Updated Task'),
              taskBaseModel: TaskBaseModel(),
            ),
            taskRequestModel: TaskRequestModel(),
          ),
        ),
      );

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      expect(success.value, isA<UpdateTaskResponse200>());
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/api/1.0/tasks/11111');
      expect(recordedRequest.method, 'PUT');
    });
  });

  // ── DELETE /tasks/{taskGid} (DeleteTask) ─────────────────────────────

  group('DeleteTask', () {
    test('delete_task 200', () async {
      final api = TasksApi(buildServer(responseStatus: '200'));

      final result = await api.deleteTask(taskGid: '11111');

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      expect(success.value, isA<DeleteTaskResponse200>());
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/api/1.0/tasks/11111');
      expect(recordedRequest.method, 'DELETE');
    });
  });
}
