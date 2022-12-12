export const setpageTitle = () => ({
  type: "SET_PAGETITLE",
  title: "Breeding Capacity"
});

export const periodAdd = obj => ({
  type: "LEAF_DISK_CAPACITY_PLANNING_ADD_PERIOD",
  data: obj
});

export const displayPeriodAdd = period => ({
  type: "LEAF_DISK_CAPACITY_PLANNING_PERIOD_ADD",
  period
});

export const displayPeriodExpected = period => ({
  type: "LEAF_DISK_CAPACITY_PLANNING_EXPECTED_ADD",
  period
});

export const breedingFomrData = data => ({
  type: "LEAF_DISK_CAPACITY_PLANNING_FORM_VALUE",
  data
});

export const breedingMessage = message => ({
  type: "LEAF_DISK_CAPACITY_PLANNING_ERROR_ADD",
  message
});

export const breedingSubmit = submit => ({
  type: "LEAF_DISK_CAPACITY_PLANNING_SUBMIT",
  submit
});

export const breedingForced = forced => ({
  type: "LEAF_DISK_CAPACITY_PLANNING_FORCED",
  forced
});

export const breedingReset = () => ({
  type: "LEAF_DISK_CAPACITY_PLANNING_RESET"
});

export const breedingMaterialType = materialType => ({
  type: "LEAF_DISK_CAPACITY_PLANNING_MATERIALTYPE",
  materialType
});

export const periodFetch = (date, period) => ({
  type: "LEAF_DISK_CAPACITY_PLANNING_PERIOD_FETCH",
  period,
  date
});

export const fetchAvailSamples = (
  testProtocolID,
  plannedDate,
  siteID
) => ({
  type: "LEAF_DISK_CAPACITY_PLANNING_AVAIL_SAMPLE_FETCH",
  testProtocolID,
  plannedDate,
  siteID
});

// 2018 4 4
export const breederSumbit = submit => ({
  type: "LEAF_DISK_CAPACITY_PLANNING_SUBMIT",
  submit
});

export const breederReset = () => ({
  type: "LEAF_DISK_CAPACITY_PLANNING_RESET"
});

export const notificationShow = obj =>
  Object.assign({}, obj, { type: "NOTIFICATION_SHOW" });

export const breederReserve = obj =>
  Object.assign({}, obj, { type: "LEAF_DISK_CAPACITY_PLANNING_RESERVE" });

export const breederErrorClear = () => ({
  type: "LEAF_DISK_CAPACITY_PLANNING_ERROR_CLEAR"
});

export const expectedBlank = () => ({
  type: "LEAF_DISK_CAPACITY_PLANNING_EXPECTED_BLANK"
});

export const breederFetchMaterialType = crop => ({
  type: "LEAF_DISK_CAPACITY_PLANNING_FETCH_MATERIALTYPE",
  crop
});

export const breederFieldFetch = () => ({
  type: "LEAF_DISK_CAPACITY_PLANNING_FETCH"
});

export const breederSlotFetch = (
  cropCode,
  brStationCode,
  pageNumber,
  pageSize,
  filter
) => ({
  type: "LEAF_DISK_FETCH_BREEDER_SLOT",
  cropCode,
  brStationCode,
  pageNumber,
  pageSize,
  filter
});
export const breederUpdate = update => ({
  type: "LEAF_DISK_CAPACITY_PLANNING_UPDATE",
  update
});
export const breederUpdateForced = forceUpdate => ({
  type: "LEAF_DISK_CAPACITY_PLANNING_UPDATE_FORCED",
  forceUpdate
});

export const leafDiskExportCapacityPlanning = payload => ({
  type: "LEAF_DISK_EXPORT_CAPACITY_PLANNING",
  payload
});

export const slotFetch = (
  cropCode,
  brStationCode,
  pageNumber,
  pageSize,
  filter
) => ({
  type: "LEAF_DISK_FETCH_BREEDER_SLOT",
  cropCode,
  brStationCode,
  pageNumber,
  pageSize,
  filter
});

export const clearFilter = () => ({
  type: "LEAF_DISK_FILTER_BREEDER_SLOT_CLEAR"
});

export const addFilter = (
  name,
  value,
  expression,
  operator,
  dataType,
  traitID
) => ({
  type: "LEAF_DISK_FILTER_BREEDER_SLOT_ADD",
  name,
  value,
  expression,
  operator,
  dataType,
  traitID
});

export const addSelectedCrop = crop => ({
  type: "LEAF_DISK_ADD_SELECTED_CROP",
  crop
});

export const fetchBreedingStation = () => ({
  type: "LEAF_DISK_FETCH_BREEDING_STATION"
});

export const breedingStationSelected = selected => ({
  type: "LEAF_DISK_BREEDING_STATION_SELECTED",
  selected
});
