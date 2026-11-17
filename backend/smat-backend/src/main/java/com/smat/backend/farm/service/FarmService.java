
package com.smat.backend.farm.service;

import com.smat.backend.farm.dto.CreateFarmRequest;
import com.smat.backend.farm.dto.FarmResponse;
import com.smat.backend.farm.entity.Farm;
import com.smat.backend.organization.repository.OrganizationRepository;
import com.smat.backend.farm.repository.FarmRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class FarmService {

    private final FarmRepository repository;
    private final OrganizationRepository organizationRepository;

    public FarmService(FarmRepository repository, OrganizationRepository organizationRepository) {
        this.repository = repository;
        this.organizationRepository = organizationRepository;
    }

    @Transactional(readOnly = true)
    public List<FarmResponse> findByOrganization(Long organizationId) {
        return repository.findByOrganizationId(organizationId)
                .stream()
                .map(f -> new FarmResponse(
                        f.getId(),
                        f.getFarmCode(),
                        f.getFarmName()
                ))
                .toList();
    }

    @Transactional
    public FarmResponse create(
            Long organizationId,
            CreateFarmRequest request
    ) {
        var organization = organizationRepository
                .findById(organizationId)
                .orElseThrow(() ->
                        new IllegalArgumentException(
                                "Organization does not exist"
                        )
                );

        if (!"ACTIVE".equals(organization.getStatus())) {
            throw new IllegalArgumentException(
                    "Organization is not active"
            );
        }

        String code = request.farmCode().trim();

        if (repository.existsByOrganizationIdAndFarmCode(
                organizationId, code)) {
            throw new IllegalStateException(
                    "Farm code already exists"
            );
        }

        Farm farm = new Farm(
                organizationId,
                code,
                request.farmName().trim(),
                request.addressText()
        );

        Farm saved = repository.save(farm);

        return new FarmResponse(
                saved.getId(),
                saved.getFarmCode(),
                saved.getFarmName()
        );

    }
}
