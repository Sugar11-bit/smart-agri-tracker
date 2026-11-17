
package com.smat.backend.planting.service;

import com.smat.backend.planting.entity.Planting;
import com.smat.backend.planting.dto.CreatePlantingRequest;
import com.smat.backend.planting.dto.PlantingResponse;
import com.smat.backend.planting.dto.*;

import com.smat.backend.planting.repository.PlantingRepository;
import com.smat.backend.plot.repository.PlotRepository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class PlantingService {

    private final PlantingRepository plantingRepository;
    private final PlotRepository plotRepository;
    private final JdbcTemplate jdbc;

    public PlantingService(PlantingRepository plantingRepository, PlotRepository plotRepository, JdbcTemplate jdbc) {
        this.plantingRepository = plantingRepository;
        this.plotRepository = plotRepository;
        this.jdbc = jdbc;
    }

    @Transactional(readOnly = true)
    public List<PlantingResponse> findByPlot(Long organizationId, Long plotId) {

        if (!plotRepository.existsByOrganizationIdAndId(organizationId, plotId)) {
            throw new IllegalArgumentException(
                    "Plot does not belong to organization"
            );
        }

        return plantingRepository
                .findByOrganizationIdAndPlotId(organizationId, plotId)
                .stream()
                .map(p -> new PlantingResponse(
                        p.getId(),
                        p.getPlotId(),
                        p.getCropTypeId(),
                        p.getPlantingCode(),
                        p.getStatus()
                ))
                .toList();
    }

    @Transactional
    public PlantingResponse create(
            Long organizationId,
            CreatePlantingRequest request) {

        if (!plotRepository.existsByOrganizationIdAndId(
                organizationId, request.plotId())) {
            throw new IllegalArgumentException(
                    "Plot does not belong to organization"
            );
        }

        Integer cropCount = jdbc.queryForObject(
                "SELECT COUNT(*) FROM crop_types WHERE id = ?",
                Integer.class,
                request.cropTypeId()
        );

        if (cropCount == null || cropCount == 0) {
            throw new IllegalArgumentException(
                    "Crop type does not exist"
            );
        }

        if (request.varietyId() != null) {
            Integer varietyCount = jdbc.queryForObject(
                    """
                    SELECT COUNT(*)
                    FROM crop_varieties
                    WHERE id = ? AND crop_type_id = ?
                    """,
                    Integer.class,
                    request.varietyId(),
                    request.cropTypeId()
            );

            if (varietyCount == null || varietyCount == 0) {
                throw new IllegalArgumentException(
                        "Variety does not match crop type"
                );
            }
        }

        String code = request.plantingCode().trim();

        if (plantingRepository
                .existsByOrganizationIdAndPlantingCode(
                        organizationId, code)) {
            throw new IllegalStateException(
                    "Planting code already exists"
            );
        }

        Planting planting = new Planting(
                organizationId,
                request.plotId(),
                request.cropTypeId(),
                request.varietyId(),
                code,
                request.plantedAt()
        );

        Planting saved = plantingRepository.save(planting);

        return new PlantingResponse(
                saved.getId(),
                saved.getPlotId(),
                saved.getCropTypeId(),
                saved.getPlantingCode(),
                saved.getStatus()
        );
    }
}
