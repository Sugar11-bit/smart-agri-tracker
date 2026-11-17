package com.smat.backend.security;

import java.net.URI;
import java.net.http.*;
import java.security.SecureRandom;
import java.util.Base64;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import static org.junit.jupiter.api.Assertions.assertEquals;

@SpringBootTest(webEnvironment=SpringBootTest.WebEnvironment.RANDOM_PORT,properties={
        "spring.profiles.active=production", "spring.flyway.enabled=false", "smat.bootstrap.enabled=false"})
class ProductionSecurityTests {
    @LocalServerPort int port;
    @DynamicPropertySource static void secret(DynamicPropertyRegistry registry) {
        byte[] bytes=new byte[32];
        new SecureRandom().nextBytes(bytes);
        String secret=Base64.getEncoder().encodeToString(bytes);
        registry.add("smat.jwt.secret",()->secret);
    }
    int status(String path) throws Exception {
        return HttpClient.newHttpClient().send(HttpRequest.newBuilder(
                URI.create("http://127.0.0.1:"+port+path)).GET().build(),
                HttpResponse.BodyHandlers.discarding()).statusCode();
    }
    @Test void developmentApiIsNotPublicOutsideDev() throws Exception {
        assertEquals(401,status("/api/v1/dev/farms?organizationId=1"));
    }
    @Test void developmentPageIsNotPublicOutsideDev() throws Exception {
        assertEquals(401,status("/admin-smat.html"));
    }
}
