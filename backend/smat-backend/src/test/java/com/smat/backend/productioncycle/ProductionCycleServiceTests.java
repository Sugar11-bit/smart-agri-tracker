package com.smat.backend.productioncycle;

import com.smat.backend.planting.repository.PlantingRepository;
import com.smat.backend.productioncycle.dto.CreateProductionCycleRequest;
import com.smat.backend.productioncycle.repository.ProductionCycleRepository;
import com.smat.backend.productioncycle.service.ProductionCycleService;
import org.junit.jupiter.api.Test;
import java.time.LocalDate;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class ProductionCycleServiceTests {
    private final ProductionCycleRepository cycles = mock(ProductionCycleRepository.class);
    private final PlantingRepository plantings = mock(PlantingRepository.class);
    private final ProductionCycleService service = new ProductionCycleService(cycles, plantings);
    private final LocalDate start = LocalDate.of(2026, 10, 29);

    @Test void rejectsPlantingFromAnotherOrganization() {
        assertThrows(IllegalArgumentException.class, () -> service.create(1L,
                new CreateProductionCycleRequest(2L, "C1", null, start, null)));
        verifyNoInteractions(cycles);
    }

    @Test void rejectsReversedDates() {
        when(plantings.existsByOrganizationIdAndId(1L, 2L)).thenReturn(true);
        assertThrows(IllegalArgumentException.class, () -> service.create(1L,
                new CreateProductionCycleRequest(2L, "C1", 2026, start, start.minusDays(1))));
        verifyNoInteractions(cycles);
    }

    @Test void rejectsDuplicateTrimmedCode() {
        when(plantings.existsByOrganizationIdAndId(1L, 2L)).thenReturn(true);
        when(cycles.existsByOrganizationIdAndCycleCode(1L, "C1")).thenReturn(true);
        assertThrows(IllegalStateException.class, () -> service.create(1L,
                new CreateProductionCycleRequest(2L, " C1 ", null, start, null)));
        verify(cycles, never()).save(any());
    }

    @Test void createsDraftWithOptionalFieldsUnset() {
        when(plantings.existsByOrganizationIdAndId(1L, 2L)).thenReturn(true);
        when(cycles.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
        var result = service.create(1L, new CreateProductionCycleRequest(2L, " C1 ", null, start, null));
        assertEquals("DRAFT", result.status());
        assertEquals("C1", result.cycleCode());
        assertNull(result.cycleYear());
        assertNull(result.endDate());
    }

    @Test void rejectsListingAnotherOrganizationsPlanting() {
        assertThrows(IllegalArgumentException.class, () -> service.list(1L, 2L));
        verifyNoInteractions(cycles);
    }
}
