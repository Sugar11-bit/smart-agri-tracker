
    const $ = id => document.getElementById(id);


    function resetCycleSelection() {
    $("plantingSelect").replaceChildren(
        new Option("Chọn Planting", "")
    );
    $("cycleList").replaceChildren();
}

    function resetPlantingSelection() {
    $("plotSelect").replaceChildren(
        new Option("Chọn Plot", "")
    );
    $("plantingList").replaceChildren();
    resetCycleSelection();
}

    $("farmSelect").addEventListener("change", () => {
    $("plotList").replaceChildren();
    resetPlantingSelection();
});

    $("plotSelect").addEventListener("change", () => {
    $("plantingList").replaceChildren();
    resetCycleSelection();
});

    $("plantingSelect").addEventListener("change", () => {
    $("cycleList").replaceChildren();
});


    //Bổ sung 2 hàm


    async function loadPlantings() {
    try {
    const orgId = getOrganizationId();
    const plotId = Number($("plotSelect").value);

    if (!Number.isSafeInteger(plotId) || plotId <= 0) {
    throw new Error("Vui lòng chọn Plot");
}

    const plantings = await apiRequest(
    `/api/v1/dev/plantings?organizationId=${orgId}` +
    `&plotId=${plotId}`
    );

    if (Number($("organizationId").value) !== orgId
        || Number($("plotSelect").value) !== plotId) return;

    $("plantingList").replaceChildren();
    $("plantingSelect").replaceChildren(
    new Option("Chọn Planting", "")
    );
    $("cycleList").replaceChildren();

    for (const planting of plantings) {
    const li = document.createElement("li");

    li.textContent =
    `${planting.plantingCode} — ${planting.status}`;

    $("plantingList").appendChild(li);

    $("plantingSelect").add(
    new Option(
    planting.plantingCode,
    String(planting.id)
    )
    );
}

    showMessage(`Đã tải ${plantings.length} Planting.`);
} catch (error) {
    showMessage(`Lỗi tải Planting: ${error.message}`);
}
}

    async function loadCycles() {
    try {
    const orgId = getOrganizationId();
    const plantingId =
    Number($("plantingSelect").value);

    if (!Number.isSafeInteger(plantingId)
    || plantingId <= 0) {
    throw new Error("Vui lòng chọn Planting");
}

    const cycles = await apiRequest(
    `/api/v1/dev/production-cycles` +
    `?organizationId=${orgId}` +
    `&plantingId=${plantingId}`
    );

    if (Number($("organizationId").value) !== orgId
        || Number($("plantingSelect").value) !== plantingId) return;

    $("cycleList").replaceChildren();

    for (const cycle of cycles) {
    const li = document.createElement("li");

    li.textContent =
    `${cycle.cycleCode} — ${cycle.cycleYear ?? ""}` +
    ` — ${cycle.status}`;

    $("cycleList").appendChild(li);
}

    showMessage(`Đã tải ${cycles.length} kỳ sản xuất.`);
} catch (error) {
    showMessage(`Lỗi tải Cycle: ${error.message}`);
}
}

    $("loadPlantingsBtn")
    .addEventListener("click", loadPlantings);

    $("loadCyclesBtn")
    .addEventListener("click", loadCycles);


    function showMessage(text) {
    $("message").textContent = text;
}

    function getOrganizationId() {
    const id = Number($("organizationId").value);

    if (!Number.isSafeInteger(id) || id <= 0) {
    throw new Error("Organization ID không hợp lệ");
}

    return id;
}

    async function apiRequest(url, options = {}) {
    let response;

    try {
    response = await fetch(url, options);
} catch (error) {
    throw new Error(
    "Không kết nối được Backend. " +
    "Kiểm tra Spring Boot đang chạy ở cổng 8080."
    );
}

    const raw = await response.text();

    let data;

    try {
    data = raw ? JSON.parse(raw) : null;
} catch {
    data = raw;
}

    if (!response.ok) {
    console.error("API ERROR", {
    url,
    status: response.status,
    response: data
});

    const message =
    data && typeof data === "object"
    ? data.message || data.detail || data.error
    : typeof data === "string"
    ? data.slice(0, 300)
    : null;

    throw new Error(
    `HTTP ${response.status}: ` +
    (message || "Request failed")
    );
}

    return data;
}


    function jsonPost(body) {
    return {
    method: "POST",
    headers: {
    "Content-Type": "application/json"
},
    body: JSON.stringify(body)
};
}

    async function loadFarms() {
    try {
    const orgId = getOrganizationId();

    const farms = await apiRequest(
    `/api/v1/dev/farms?organizationId=${orgId}`
    );

    if (Number($("organizationId").value) !== orgId) return;

    const list = $("farmList");
    const select = $("farmSelect");

    list.replaceChildren();
    select.replaceChildren(
    new Option("Chọn Farm", "")
    );
    $("plotList").replaceChildren();
    resetPlantingSelection();

    for (const farm of farms) {
    const li = document.createElement("li");

    li.textContent =
    `${farm.farmCode} — ${farm.farmName}`;

    list.appendChild(li);

    select.add(
    new Option(
    `${farm.farmCode} — ${farm.farmName}`,
    String(farm.id)
    )
    );
}

    showMessage(`Đã tải ${farms.length} Farm.`);
} catch (error) {
    showMessage(`Lỗi tải Farm: ${error.message}`);
}
}

    async function loadPlots() {
    try {
    const orgId = getOrganizationId();
    const farmId = Number($("farmSelect").value);

    if (!Number.isSafeInteger(farmId) || farmId <= 0) {
    throw new Error("Bạn chưa chọn Farm");
}

    const plots = await apiRequest(
    `/api/v1/dev/plots?organizationId=${orgId}` +
    `&farmId=${farmId}`
    );

    if (Number($("organizationId").value) !== orgId
        || Number($("farmSelect").value) !== farmId) return;

    const list = $("plotList");
    list.replaceChildren();

    for (const plot of plots) {
    const li = document.createElement("li");

    li.textContent =
    `${plot.plotCode} — ${plot.plotName}` +
    ` — ${plot.areaHectares} ha`;

    list.appendChild(li);
}

    const plotSelect = $("plotSelect");
    plotSelect.replaceChildren(
    new Option("Chọn Plot", "")
    );

    $("plantingSelect").replaceChildren(
    new Option("Chọn Planting", "")
    );
    $("plantingList").replaceChildren();
    $("cycleList").replaceChildren();

    for (const plot of plots) {
    plotSelect.add(
    new Option(
    `${plot.plotCode} — ${plot.plotName}`,
    String(plot.id)
    )
    );
}

    showMessage(`Đã tải ${plots.length} Plot.`);
} catch (error) {
    showMessage(`Lỗi tải Plot: ${error.message}`);
}
}

    $("loadFarmsBtn")
    .addEventListener("click", loadFarms);

    $("loadPlotsBtn")
    .addEventListener("click", loadPlots);

    $("farmForm").addEventListener(
    "submit", async event => {
    event.preventDefault();

    try {
    const orgId = getOrganizationId();

    const body = {
    farmCode: $("farmCode").value.trim(),
    farmName: $("farmName").value.trim(),
    addressText: $("farmAddress").value.trim()
};


    const saved = await apiRequest(
    `/api/v1/dev/farms?organizationId=${orgId}`,
    jsonPost(body)
    );

    $("farmForm").reset();
    await loadFarms();
    showMessage(`Tạo Farm thành công: ID ${saved.id}`);

} catch (error) {
    showMessage(`Lỗi tạo Farm: ${error.message}`);
}
}
    );

    $("plotForm").addEventListener(
    "submit", async event => {
    event.preventDefault();

    try {
    const orgId = getOrganizationId();
    const farmId = Number($("farmSelect").value);

    if (!Number.isSafeInteger(farmId) || farmId <= 0) {
    throw new Error("Bạn chưa chọn Farm");
}

    const body = {
    farmId: farmId,
    plotCode: $("plotCode").value.trim(),
    plotName: $("plotName").value.trim(),
    areaHectares: Number($("plotArea").value)
};

    const saved = await apiRequest(
    `/api/v1/dev/plots?organizationId=${orgId}`,
    jsonPost(body)
    );

    $("plotForm").reset();
    await loadPlots();
    showMessage(`Tạo Plot thành công: ID ${saved.id}`);

} catch (error) {
    showMessage(`Lỗi tạo Plot: ${error.message}`);
}
}
    );

    $("organizationId").addEventListener("input", () => {
    $("farmList").replaceChildren();
    $("farmSelect").replaceChildren(
    new Option("Chọn Farm", "")
    );

    $("plotList").replaceChildren();
    $("plotSelect").replaceChildren(
    new Option("Chọn Plot", "")
    );

    $("plantingList").replaceChildren();
    $("plantingSelect").replaceChildren(
    new Option("Chọn Planting", "")
    );

    $("cycleList").replaceChildren();
});


    $("plantingForm").addEventListener(
    "submit", async event => {
    event.preventDefault();

    try {
    const orgId = getOrganizationId();
    const plotId = Number($("plotSelect").value);

    if (!Number.isSafeInteger(plotId) || plotId <= 0) {
    throw new Error("Vui lòng chọn Plot trước");
}

    const cropTypeId =
    Number($("cropTypeId").value);

    if (!Number.isSafeInteger(cropTypeId)
    || cropTypeId <= 0) {
    throw new Error("Vui lòng chọn loại cây trồng");
}

    const varietyRaw = $("varietyId").value.trim();

    const varietyId = varietyRaw === ""
    ? null
    : Number(varietyRaw);

    if (varietyId !== null
    && (!Number.isSafeInteger(varietyId)
    || varietyId <= 0)) {
    throw new Error("Variety ID không hợp lệ");
}

    const body = {
    plotId: plotId,
    cropTypeId: cropTypeId,
    varietyId: varietyId,
    plantingCode: $("plantingCode").value.trim(),
    plantedAt: $("plantedAt").value || null
};

    const saved = await apiRequest(
    `/api/v1/dev/plantings` +
    `?organizationId=${orgId}`,
    jsonPost(body)
    );

    $("plantingForm").reset();

    await loadPlantings();

    $("plantingSelect").value = String(saved.id);

    showMessage(
    `Đã tạo Planting thành công. ID: ${saved.id}`
    );

} catch (error) {
    showMessage(
    `Lỗi tạo Planting: ${error.message}`
    );
}
}
    );


    $("cycleForm").addEventListener(
    "submit", async event => {
    event.preventDefault();

    try {
    const orgId = getOrganizationId();

    const plantingId =
    Number($("plantingSelect").value);

    if (!Number.isSafeInteger(plantingId)
    || plantingId <= 0) {
    throw new Error(
    "Vui lòng chọn Planting trước"
    );
}

    const startDate = $("cycleStartDate").value;
    const endDate = $("cycleEndDate").value;

    if (!startDate) {
    throw new Error(
    "Ngày bắt đầu không được để trống"
    );
}

    if (endDate && endDate < startDate) {
    throw new Error(
    "Ngày kết thúc phải từ ngày bắt đầu trở đi"
    );
}

    const yearRaw = $("cycleYear").value.trim();

    const cycleYear = yearRaw === ""
    ? null
    : Number(yearRaw);

    if (cycleYear !== null
    && (!Number.isInteger(cycleYear)
    || cycleYear < 1900
    || cycleYear > 2200)) {
    throw new Error(
    "Năm sản xuất không hợp lệ"
    );
}

    const body = {
    plantingId: plantingId,
    cycleCode: $("cycleCode").value.trim(),
    cycleYear: cycleYear,
    startDate: startDate,
    endDate: endDate || null
};

    const saved = await apiRequest(
    `/api/v1/dev/production-cycles` +
    `?organizationId=${orgId}`,
    jsonPost(body)
    );

    $("cycleForm").reset();

    await loadCycles();

    showMessage(
    `Đã tạo ProductionCycle. ID: ${saved.id}`
    );

} catch (error) {
    showMessage(
    `Lỗi tạo ProductionCycle: ${error.message}`
    );
}
}
    );


    async function loadCropTypes() {
        const select = $("cropTypeId");

        select.disabled = true;
        select.replaceChildren(
            new Option("Đang tải loại cây...", "")
        );

        try {
            const crops = await apiRequest(
                "/api/v1/dev/crop-types"
            );

            if (!Array.isArray(crops)) {
                throw new Error("API không trả về danh sách");
            }

            select.replaceChildren(
                new Option("Chọn loại cây trồng", "")
            );

            for (const crop of crops) {
                select.add(
                    new Option(
                        `${crop.cropName} (${crop.cropCode})`,
                        String(crop.id)
                    )
                );
            }

            select.disabled = false;

            if (crops.length === 0) {
                showMessage(
                    "Chưa có CropType. Hãy thêm dữ liệu " +
                    "vào bảng crop_types."
                );
            }

        } catch (error) {
            select.replaceChildren(
                new Option("Không tải được loại cây", "")
            );

            showMessage(
                `Lỗi tải CropType: ${error.message}`
            );
        }
    }
    loadCropTypes();
