
package com.smat.backend.plot.service;

import com.smat.backend.farm.repository.FarmRepository;
import com.smat.backend.plot.dto.*;
import com.smat.backend.plot.entity.Plot;
import com.smat.backend.plot.repository.PlotRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class PlotService {

    private final PlotRepository plotRepository;
    private final FarmRepository farmRepository;

    public PlotService(
            PlotRepository plotRepository,
            FarmRepository farmRepository) {
        this.plotRepository = plotRepository;
        this.farmRepository = farmRepository;
    }

    @Transactional
    public PlotResponse create(Long organizationId, CreatePlotRequest request) {

        if (!farmRepository.existsByOrganizationIdAndId(
                organizationId, request.farmId())) {
            throw new IllegalArgumentException(
                    "Farm does not belong to organization"
            );
        }

        String code = request.plotCode().trim();

        if (plotRepository.existsByOrganizationIdAndPlotCode(
                organizationId, code)) {
            throw new IllegalStateException(
                    "Plot code already exists"
            );
        }

        Plot plot = new Plot(
                organizationId,
                request.farmId(),
                code,
                request.plotName().trim(),
                request.areaHectares()
        );

        Plot saved = plotRepository.save(plot);

        return toResponse(saved);
    }

    @Transactional(readOnly = true)
    public List<PlotResponse> findByFarm(
            Long organizationId, Long farmId) {

        return plotRepository
                .findByOrganizationIdAndFarmId(
                        organizationId, farmId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    private PlotResponse toResponse(Plot plot) {
        return new PlotResponse(
                plot.getId(),
                plot.getFarmId(),
                plot.getPlotCode(),
                plot.getPlotName(),
                plot.getAreaHectares()
        );
    }
}
