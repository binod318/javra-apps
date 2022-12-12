export const setpageTitle = () => ({
  type: "SET_PAGETITLE",
  title: "Breeding Capacity"
});

export const periodAdd = obj => ({
  type: "ADD_PERIOD",
  data: obj
});

export const displayPeriodAdd = period => ({
  type: "PERIOD_ADD",
  period
});

export const displayPeriodExpected = period => ({
  type: "EXPECTED_ADD",
  period
});

export const breedingFomrData = data => ({
  type: "BREEDER_FORM_VALUE",
  data
});

export const breedingMessage = message => ({
  type: "BREEDER_ERROR_ADD",
  message
});

export const breedingSubmit = submit => ({
  type: "BREEDER_SUBMIT",
  submit
});

export const breedingForced = forced => ({
  type: "BREEDER_FORCED",
  forced
});

export const breedingReset = () => ({
  type: "BREEDER_RESET"
});

export const breedingMaterialType = materialType => ({
  type: "BREEDER_MATERIALTYPE",
  materialType
});

export const periodFetch = (date, period) => ({
  type: "PERIOD_FETCH",
  period,
  date
});

export const platesTestFetch = (
  plannedDate,
  cropCode,
  materialTypeID,
  isolated,
  expectedDate
) => ({
  type: "PLATES_TESTS_FETCH",
  plannedDate,
  cropCode,
  materialTypeID,
  isolated,
  expectedDate
});

// 2018 4 4
export const breederSumbit = submit => ({
  type: "BREEDER_SUBMIT",
  submit
});

export const breederReset = () => ({
  type: "BREEDER_RESET"
});

export const notificationShow = obj =>
  Object.assign({}, obj, { type: "NOTIFICATION_SHOW" });

export const breederReserve = obj =>
  Object.assign({}, obj, { type: "BREEDER_RESERVE" });

export const breederErrorClear = () => ({
  type: "BREEDER_ERROR_CLEAR"
});

export const expectedBlank = () => ({
  type: "EXPECTED_BLANK"
});

export const breederFetchMaterialType = crop => ({
  type: "BREEDER_FETCH_MATERIALTYPE",
  crop
});

export const breederFieldFetch = () => ({
  type: "BREEDER_FIELD_FETCH"
});

export const breederSlotFetch = (
  cropCode,
  brStationCode,
  pageNumber,
  pageSize,
  filter
) => ({
  type: "FETCH_BREEDER_SLOT",
  cropCode,
  brStationCode,
  pageNumber,
  pageSize,
  filter
});
export const breederUpdate = update => ({ type: "BREEDER_UPDATE", update });
export const breederUpdateForced = forceUpdate => ({
  type: "BREEDER_UPDATE_FORCED",
  forceUpdate
});

export const exportCapacityPlanning = payload => ({
  type: "EXPORT_CAPACITY_PLANNING",
  payload
});
