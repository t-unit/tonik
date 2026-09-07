# Spring Boot MVC + springdoc

```sh
./examples/run.sh java_spring_boot --backend both
```

Java 17, Maven 3.9.11, Spring Boot 3.5.5 and springdoc 2.8.13 are pinned in the
Dockerfile and Maven parent/dependency declarations. The runtime image is
Eclipse Temurin 17.0.16_8. Spring's controllers, Jackson models and Swagger
annotations produce **OpenAPI 3.0.1** at `/openapi.json`. JSON `produces` is
explicit so springdoc does not advertise wildcard `*/*` for JSON models.

The standalone Dart client has 18 explicit live tests.

| Case | Producer behavior | Runtime/parser setup | Dio | HTTP | Limitation/evidence |
| --- | --- | --- | --- | --- | --- |
| JSON/formats/maps/null | Records and Schema metadata | Jackson | Pass | Pass | Initial timestamp has +02:00; Jackson normalizes its echoed value to UTC. |
| Path/query/header/cookie | Spring parameter annotations | Servlet/Spring binding | Pass | Pass | Repeated raw parameter values preserve literal commas inside each element. |
| URL-encoded form | FormFields request schema | FormHttpMessageConverter and MultiValueMap | Pass | Pass | ContentCachingRequestWrapper captures the bytes read by the converter. |
| Multipart file/scalars | Explicit UploadFields request schema | Spring MultipartFile and RequestParam | Pass | Pass | File and scalars really travel in multipart, including a zero-byte path file. |
| Typed JSON multipart part | RequestPart + explicit Encoding contentType | Jackson deserializes Metadata part | Pass | Pass | Receipt reads actual part Content-Type; optional charset is allowed. |
| Binary/four charsets | Explicit byte-body schemas/media | byte[] and Charset encoders | Pass | Pass | UTF-8, Latin-1, Windows-1252 and Shift-JIS are actual bytes. |
| `oneOf` | Union annotation on PaymentDocument.payment | Jackson polymorphic property | Pass | Pass | Both card and bank; card echo. |
| `allOf` | Details references Product and Audit | Flat JSON handler result | Pass | Pass | Real flat JSON decoded into both constituents. |
| 201/204/404 | Spring status annotations | Real handlers | Pass | Pass | Distinct customer input plus raw response checks secret omission. |
| gzip | Standard embedded-server compression | Threshold 1 byte | Enabled; not explicitly asserted | Enabled; not explicitly asserted | Separate from charsets. |

Two producer/runtime details are deliberate. Putting the same polymorphic union
on both the base interface and subtypes produced a circular schema; placing the
Jackson and schema annotations on the containing payment property produces the
valid union used here. For repeated query values, Spring's List conversion can
split commas; the receipt uses the Servlet API's parsed parameter array to
preserve each value exactly.

The echo test explicitly asserts Jackson's native UTC normalization. Instant
comparison alone would miss that offset change. Native Bean Validation errors,
`anyOf`, file arrays and advanced parameter styles remain follow-ups for this
stack. Typed JSON parts are covered here rather than represented as JSON strings
in ordinary form fields.

References: [springdoc](https://springdoc.org/),
[Spring multipart](https://docs.spring.io/spring-framework/reference/web/webmvc/mvc-controller/ann-methods/multipart-forms.html),
[Spring form converter](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/http/converter/FormHttpMessageConverter.html).
