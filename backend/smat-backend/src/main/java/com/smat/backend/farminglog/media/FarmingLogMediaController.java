
package com.smat.backend.farminglog.media;

import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/me/farming-logs")
public class FarmingLogMediaController {

    private final FarmingLogLocationService locations;
    private final FarmingLogPhotoService photos;

    public FarmingLogMediaController(
            FarmingLogLocationService locations,
            FarmingLogPhotoService photos
    ) {
        this.locations = locations;
        this.photos = photos;
    }

    @PutMapping("/{logId}/location")
    public ResponseEntity<
            FarmingLogLocationService.LocationResponse
            > saveLocation(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable Long logId,
            @RequestBody
            FarmingLogLocationService.LocationRequest request
    ) {
        var result = locations.save(
                jwt, logId, request
        );

        return ResponseEntity
                .status(result.created()
                        ? HttpStatus.CREATED
                        : HttpStatus.OK)
                .body(result.location());
    }

    @PostMapping(
            value = "/{logId}/photos",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE
    )
    public ResponseEntity<
            FarmingLogPhotoService.PhotoResponse
            > uploadPhoto(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable Long logId,
            @RequestParam UUID clientPhotoId,
            @RequestPart("file") MultipartFile file
    ) {
        var result = photos.upload(
                jwt, logId, clientPhotoId, file
        );

        return ResponseEntity
                .status(result.created()
                        ? HttpStatus.CREATED
                        : HttpStatus.OK)
                .body(result.photo());
    }
}
