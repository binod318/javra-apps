export const labCapacityData = data => ({
  type: "LD_LAB_DATA_ADD",
  data
});

export const labCapacityColumn = data => ({
  type: "LD_LAB_COLUMN_ADD",
  data
});

export const labFetch = (year, siteLocation) => ({
  type: "LD_LAB_DATA_FETCH",
  year,
  siteLocation
});

export const labDataChange = (index, key, value) => ({
  type: "LD_LAB_DATA_CHANGE",
  index,
  key,
  value
});

export const labDataRowChange = (key, value) => ({
  type: "LD_LAB_DATE_ROW_CHANGE",
  key,
  value
});

export const labDataUpdate = (siteLocation, data, year) => ({
  type: "LD_LAB_DATA_UPDATE",
  siteLocation,
  data,
  year
});
