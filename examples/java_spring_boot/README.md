# Spring Boot MVC + springdoc

From the repository root ([setup](../README.md#run)):

```sh
./examples/run.sh java_spring_boot
```

[Main.java](server/src/main/java/example/Main.java) uses Spring Boot 3.5.5 and
springdoc 2.8.13 to produce OpenAPI 3.0 from records and controller annotations.
Java 17 and Maven dependencies are pinned in the [Dockerfile](server/Dockerfile)
and [pom.xml](server/pom.xml).

- JSON response media types are explicit; otherwise springdoc advertises `*/*`.
- `/uploads/json` combines a file with a typed `application/json` part parsed by
  Jackson. Ordinary forms use Spring's form converter and `MultiValueMap`.
- Jackson normalizes the echoed timestamp from `+02:00` to UTC. Repeated query
  values use the Servlet parameter array to keep literal commas inside elements.
- Payment union annotations belong on the containing property; putting them on
  both the interface and subtypes would create a circular schema. This example
  covers `oneOf` and `allOf`.

See the [Dart demo](client/bin/example.dart), [live tests](client/test/live_test.dart),
and [Spring multipart documentation](https://docs.spring.io/spring-framework/reference/web/webmvc/mvc-controller/ann-methods/multipart-forms.html).
