package example;

import java.io.IOException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.context.annotation.Bean;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.util.ContentCachingRequestWrapper;
import org.springframework.web.util.WebUtils;
import org.springframework.util.MultiValueMap;
import java.nio.charset.Charset;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.IntStream;

import com.fasterxml.jackson.annotation.JsonSubTypes;
import com.fasterxml.jackson.annotation.JsonTypeInfo;
import io.swagger.v3.oas.annotations.Hidden;
import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.enums.Explode;
import io.swagger.v3.oas.annotations.enums.ParameterIn;
import io.swagger.v3.oas.annotations.enums.ParameterStyle;
import io.swagger.v3.oas.annotations.info.Info;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Encoding;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.servers.Server;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@SpringBootApplication
@RestController
@RequestMapping(produces = MediaType.APPLICATION_JSON_VALUE)
@Tag(name = "Catalog")
@OpenAPIDefinition(info = @Info(title = "Spring Boot catalog", version = "1.0.0"), servers = @Server(url = "http://localhost"))
public class Main {
  public static void main(String[] args) { SpringApplication.run(Main.class, args); }

  @Schema(name = "Customer", requiredProperties = {"id", "name"})
  public record Customer(UUID id, String name) {}
  @Schema(name = "Product", requiredProperties = {"id", "name", "status", "customer", "tags", "attributes", "released", "updated"})
  public record Product(int id, String name, @Schema(allowableValues = {"available", "sold"}) String status, Customer customer, List<String> tags, Map<String, Integer> attributes, LocalDate released, OffsetDateTime updated, @Schema(nullable = true) String note) {}
  @Schema(name = "Receipt", requiredProperties = {"text", "count", "enabled", "tags", "fileName", "contentType", "bytes", "raw"})
  public record Receipt(String text, int count, boolean enabled, List<String> tags, String fileName, String contentType, List<Integer> bytes, String raw) {}
  @Schema(name = "Card", requiredProperties = {"kind", "last4"})
  public record Card(@Schema(allowableValues = "card") String kind, String last4) implements Payment {}
  @Schema(name = "Bank", requiredProperties = {"kind", "iban"})
  public record Bank(@Schema(allowableValues = "bank") String kind, String iban) implements Payment {}
  public interface Payment {}
  @Schema(name = "PaymentDocument", requiredProperties = "payment")
  public record PaymentDocument(
    @JsonTypeInfo(use = JsonTypeInfo.Id.NAME, include = JsonTypeInfo.As.EXISTING_PROPERTY, property = "kind", visible = true)
    @JsonSubTypes({@JsonSubTypes.Type(value = Card.class, name = "card"), @JsonSubTypes.Type(value = Bank.class, name = "bank")})
    @Schema(oneOf = {Card.class, Bank.class}, discriminatorProperty = "kind")
    Payment payment) {}
  @Schema(name = "CustomerInput", requiredProperties = {"name", "secret"})
  public record CustomerInput(@NotBlank String name, @Schema(accessMode = Schema.AccessMode.WRITE_ONLY) String secret) {}
  @Schema(name = "ApiError", requiredProperties = "detail")
  public record ApiError(String detail) {}
  @Schema(name = "Metadata", requiredProperties = {"label", "count"})
  public record Metadata(String label, int count) {}
  @Schema(name = "UploadFields", requiredProperties = {"file", "text", "count", "enabled"})
  public record UploadFields(@Schema(type = "string", format = "binary") MultipartFile file, String text, int count, boolean enabled) {}
  @Schema(name = "JsonUpload", requiredProperties = {"file", "metadata"})
  public record JsonUpload(@Schema(type = "string", format = "binary") String file, Metadata metadata) {}
  @Schema(name = "FormFields", requiredProperties = {"text", "count", "enabled", "tags"})
  public record FormFields(String text, int count, boolean enabled, List<String> tags) {}
  @Schema(name = "Audit", requiredProperties = "source")
  public record Audit(String source) {}
  @Schema(name = "Details", allOf = {Product.class, Audit.class})
  public static class Details {}

  private static final Product PRODUCT = new Product(42, "Tea & café", "available", new Customer(UUID.fromString("123e4567-e89b-12d3-a456-426614174000"), "Ada Example"), List.of("tea", "東京"), Map.of("stock", 7), LocalDate.of(2025, 1, 2), OffsetDateTime.parse("2025-01-02T03:04:05+02:00"), null);
  private static List<Integer> bytes(byte[] value) { return IntStream.range(0, value.length).mapToObj(i -> value[i] & 255).toList(); }

  @Hidden @GetMapping("/health") public Map<String, Boolean> health() { return Map.of("ok", true); }
  @Operation(operationId = "jsonProduct") @GetMapping("/products/42") public Product product() { return PRODUCT; }
  @Operation(operationId = "echoProduct") @PostMapping("/products/echo") public Product echoProduct(@RequestBody Product body) { return body; }

  @Operation(operationId = "details", responses = @ApiResponse(responseCode = "200", content = @Content(schema = @Schema(implementation = Details.class))))
  @GetMapping("/products/42/details") public Map<String, Object> details() {
    var result = new java.util.LinkedHashMap<String, Object>();
    result.put("id", PRODUCT.id()); result.put("name", PRODUCT.name()); result.put("status", PRODUCT.status()); result.put("customer", PRODUCT.customer()); result.put("tags", PRODUCT.tags()); result.put("attributes", PRODUCT.attributes()); result.put("released", PRODUCT.released()); result.put("updated", PRODUCT.updated()); result.put("note", null); result.put("source", "fixture"); return result;
  }

  @Operation(operationId = "inspect") @GetMapping("/inspect/{key}")
  public Receipt inspect(@PathVariable String key, @RequestParam int count, @RequestParam boolean enabled, @Parameter(style = ParameterStyle.FORM, explode = Explode.TRUE) @RequestParam List<String> tags, @RequestHeader("x-trace") String trace, @CookieValue String session, HttpServletRequest request) {
    // Spring's List converter splits single values on commas. Raw parameter values preserve repeated entries.
    return new Receipt(key, count, enabled, List.of(request.getParameterValues("tags")), session, trace, List.of(), request.getQueryString());
  }

  @Bean public OncePerRequestFilter rawFormCapture() {
    return new OncePerRequestFilter() {
      @Override protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain) throws ServletException, IOException {
        if (request.getContentType() != null && request.getContentType().startsWith(MediaType.APPLICATION_FORM_URLENCODED_VALUE)) {
          chain.doFilter(new ContentCachingRequestWrapper(request), response);
        } else { chain.doFilter(request, response); }
      }
    };
  }

  @Operation(operationId = "form", requestBody = @io.swagger.v3.oas.annotations.parameters.RequestBody(content = @Content(mediaType = MediaType.APPLICATION_FORM_URLENCODED_VALUE, schema = @Schema(implementation = FormFields.class))))
  @PostMapping(value = "/forms/echo", consumes = MediaType.APPLICATION_FORM_URLENCODED_VALUE)
  public Receipt form(@RequestBody MultiValueMap<String, String> body, HttpServletRequest request) {
    var cached = WebUtils.getNativeRequest(request, ContentCachingRequestWrapper.class);
    return new Receipt(body.getFirst("text"), Integer.parseInt(body.getFirst("count")), Boolean.parseBoolean(body.getFirst("enabled")), body.get("tags"), "", request.getContentType(), List.of(), cached.getContentAsString());
  }

  @Operation(operationId = "upload", requestBody = @io.swagger.v3.oas.annotations.parameters.RequestBody(required = true, content = @Content(mediaType = MediaType.MULTIPART_FORM_DATA_VALUE, schema = @Schema(implementation = UploadFields.class)))) @PostMapping(value = "/uploads", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
  public Receipt upload(@Parameter(hidden = true) @RequestParam MultipartFile file, @Parameter(hidden = true) @RequestParam String text, @Parameter(hidden = true) @RequestParam int count, @Parameter(hidden = true) @RequestParam boolean enabled) throws IOException {
    return new Receipt(text, count, enabled, List.of(), file.getOriginalFilename(), file.getContentType(), bytes(file.getBytes()), "");
  }

  @Operation(operationId = "jsonUpload", requestBody = @io.swagger.v3.oas.annotations.parameters.RequestBody(content = @Content(mediaType = MediaType.MULTIPART_FORM_DATA_VALUE, schema = @Schema(implementation = JsonUpload.class), encoding = @Encoding(name = "metadata", contentType = "application/json"))))
  @PostMapping(value = "/uploads/json", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
  public Receipt jsonUpload(@RequestPart MultipartFile file, @RequestPart Metadata metadata, HttpServletRequest request) throws IOException, ServletException {
    return new Receipt(metadata.label(), metadata.count(), true, List.of(), file.getOriginalFilename(), file.getContentType(), bytes(file.getBytes()), request.getPart("metadata").getContentType());
  }

  @Operation(operationId = "binary", responses = @ApiResponse(responseCode = "200", content = @Content(mediaType = "application/octet-stream", schema = @Schema(type = "string", format = "binary"))))
  @GetMapping(value = "/files/sample", produces = MediaType.APPLICATION_OCTET_STREAM_VALUE) public byte[] binary() { return new byte[] {0, 1, 127, (byte)128, (byte)255}; }
  @Operation(operationId = "echoBinary", requestBody = @io.swagger.v3.oas.annotations.parameters.RequestBody(content = @Content(mediaType = "application/octet-stream", schema = @Schema(type = "string", format = "binary"))), responses = @ApiResponse(responseCode = "200", content = @Content(mediaType = "application/octet-stream", schema = @Schema(type = "string", format = "binary"))))
  @PostMapping(value = "/files/echo", consumes = MediaType.APPLICATION_OCTET_STREAM_VALUE, produces = MediaType.APPLICATION_OCTET_STREAM_VALUE) public byte[] echoBinary(@RequestBody byte[] body) { return body; }

  @Operation(operationId = "text") @GetMapping(value = "/text/{encoding}", produces = "text/plain")
  @ApiResponse(responseCode = "200", content = @Content(mediaType = "text/plain", schema = @Schema(type = "string")))
  public ResponseEntity<byte[]> text(@PathVariable String encoding) {
    String value; String charset;
    switch (encoding) {
      case "latin1" -> { value = "café"; charset = "iso-8859-1"; }
      case "windows1252" -> { value = "€ café"; charset = "windows-1252"; }
      case "shift-jis" -> { value = "東京"; charset = "shift_jis"; }
      default -> { value = "Grüße, 東京 👋"; charset = "utf-8"; }
    }
    return ResponseEntity.ok().header("Content-Type", "text/plain; charset=" + charset).body(value.getBytes(Charset.forName(charset)));
  }

  @Operation(operationId = "payment") @GetMapping("/payments/{kind}") public PaymentDocument payment(@PathVariable String kind) { return new PaymentDocument(kind.equals("card") ? new Card("card", "4242") : new Bank("bank", "DE02120300000000202051")); }
  @Operation(operationId = "echoPayment") @PostMapping("/payments/echo") public PaymentDocument echoPayment(@RequestBody PaymentDocument body) { return body; }
  @Operation(operationId = "createCustomer") @ResponseStatus(HttpStatus.CREATED) @PostMapping("/customers") public Customer createCustomer(@Valid @RequestBody CustomerInput body) { return new Customer(PRODUCT.customer().id(), body.name()); }
  @Operation(operationId = "deleteProduct") @ResponseStatus(HttpStatus.NO_CONTENT) @DeleteMapping("/products/42") public void deleteProduct() {}
  @Operation(operationId = "missing") @ResponseStatus(HttpStatus.NOT_FOUND) @GetMapping("/missing") public ApiError missing() { return new ApiError("Product not found"); }
}
