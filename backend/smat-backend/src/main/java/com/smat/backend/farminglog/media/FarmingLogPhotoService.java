
package com.smat.backend.farminglog.media;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.nio.file.*;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.List;
import java.util.UUID;

@Service
public class FarmingLogPhotoService {

    public record PhotoResponse(
            Long id,
            Long farmingLogId,
            UUID clientPhotoId,
            String contentType,
            Long fileSize,
            String sha256
    ) {}

    public record SaveResult(
            PhotoResponse photo,
            boolean created
    ) {}

    private final JdbcTemplate jdbc;
    private final FarmingLogMediaAccessService access;
    private final Path storageDirectory;

    public FarmingLogPhotoService(
            JdbcTemplate jdbc,
            FarmingLogMediaAccessService access,
            @Value(
                    "${smat.media.storage-directory:"
                            + "./data/farming-log-photos}"
            ) String storageDirectory
    ) {
        this.jdbc = jdbc;
        this.access = access;
        this.storageDirectory =
                Path.of(storageDirectory)
                        .toAbsolutePath()
                        .normalize();
    }

    public SaveResult upload(
            Jwt jwt,
            Long logId,
            UUID clientPhotoId,
            MultipartFile file
    ) {
        access.requireWritableLog(jwt, logId);

        if (clientPhotoId == null ||
                file == null ||
                file.isEmpty() ||
                file.getSize() > 5L * 1024 * 1024) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Invalid photo upload"
            );
        }

        try {
            byte[] bytes = file.getBytes();

            if (bytes.length == 0 ||
                    bytes.length > 5 * 1024 * 1024) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "Invalid photo size"
                );
            }

            String type = detectImageType(bytes);

            byte[] digest = MessageDigest
                    .getInstance("SHA-256")
                    .digest(bytes);

            String sha256 = HexFormat.of()
                    .formatHex(digest);

            PhotoResponse existing = findByClientPhotoId(
                    clientPhotoId
            );

            if (existing != null) {
                verifySame(
                        existing, logId, sha256
                );

                return new SaveResult(
                        existing, false
                );
            }

            Files.createDirectories(storageDirectory);

            String extension = type.equals("image/png")
                    ? ".png"
                    : ".jpg";

            String name =
                    UUID.randomUUID() + extension;

            Path target = storageDirectory
                    .resolve(name)
                    .normalize();

            Path temp = Files.createTempFile(
                    storageDirectory,
                    "upload-",
                    ".tmp"
            );

            boolean moved = false;

            try {
                Files.write(temp, bytes);

                try {
                    Files.move(
                            temp, target,
                            StandardCopyOption.ATOMIC_MOVE
                    );
                } catch (AtomicMoveNotSupportedException ex) {
                    Files.move(temp, target);
                }

                moved = true;

                String sql = """
                    INSERT INTO farming_log_photos (
                        farming_log_id,
                        client_photo_id,
                        file_name,
                        content_type,
                        file_size,
                        sha256
                    )
                    VALUES (?, ?, ?, ?, ?, ?)
                    ON CONFLICT (client_photo_id)
                    DO NOTHING
                    RETURNING id
                    """;

                List<Long> inserted = jdbc.query(
                        sql,
                        (rs, index) ->
                                rs.getLong("id"),
                        logId,
                        clientPhotoId,
                        name,
                        type,
                        (long) bytes.length,
                        sha256
                );

                PhotoResponse saved =
                        findByClientPhotoId(clientPhotoId);

                if (saved == null) {
                    throw new IllegalStateException(
                            "Photo record was not saved"
                    );
                }

                verifySame(
                        saved, logId, sha256
                );

                if (inserted.isEmpty()) {
                    Files.deleteIfExists(target);
                    moved = false;
                }

                return new SaveResult(
                        saved,
                        !inserted.isEmpty()
                );
            } catch (Exception error) {
                if (moved) {
                    Files.deleteIfExists(target);
                }
                throw error;
            } finally {
                Files.deleteIfExists(temp);
            }

        } catch (ResponseStatusException ex) {
            throw ex;
        } catch (IOException |
                 NoSuchAlgorithmException ex) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "Photo storage failed",
                    ex
            );
        }
    }

    private String detectImageType(byte[] bytes) {
        if (bytes.length >= 3 &&
                (bytes[0] & 0xff) == 0xff &&
                (bytes[1] & 0xff) == 0xd8 &&
                (bytes[2] & 0xff) == 0xff) {
            return "image/jpeg";
        }

        byte[] png = {
                (byte) 137, 80, 78, 71, 13, 10, 26, 10
        };

        if (bytes.length >= png.length) {
            boolean matches = true;

            for (int i = 0; i < png.length; i++) {
                if (bytes[i] != png[i]) {
                    matches = false;
                    break;
                }
            }

            if (matches) return "image/png";
        }

        throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "Only JPEG and PNG are supported"
        );
    }

    private PhotoResponse findByClientPhotoId(
            UUID clientPhotoId
    ) {
        String sql = """
            SELECT
                id, farming_log_id,
                client_photo_id,
                content_type, file_size, sha256
            FROM farming_log_photos
            WHERE client_photo_id = ?
            """;

        List<PhotoResponse> rows = jdbc.query(
                sql,
                (rs, index) -> new PhotoResponse(
                        rs.getLong("id"),
                        rs.getLong("farming_log_id"),
                        rs.getObject(
                                "client_photo_id",
                                UUID.class
                        ),
                        rs.getString("content_type"),
                        rs.getLong("file_size"),
                        rs.getString("sha256")
                ),
                clientPhotoId
        );

        return rows.isEmpty() ? null : rows.get(0);
    }

    private void verifySame(
            PhotoResponse existing,
            Long logId,
            String sha256
    ) {
        if (!existing.farmingLogId().equals(logId) ||
                !existing.sha256().equals(sha256)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Client photo ID already used"
            );
        }
    }
}
