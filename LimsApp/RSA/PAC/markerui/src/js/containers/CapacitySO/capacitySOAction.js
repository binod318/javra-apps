export const YEAR_FETCH = "YEAR_FETCH";
export const YEAR_ADD = "YEAR_ADD";
export const CAPACITY_YEAR_SELECT = "CAPACITY_YEAR_SELECT";

export const PERIOD_FETCH = "PERIOD_FETCH";
export const PERIOD_ADD = "PERIOD_ADD";
export const PERIOD_SELECT = "PERIOD_SELECT";

export const CAPACITY_DATA_FETCH = "CAPACITY_DATA_FETCH";

export const CAPACITY_DATA_ADD = "CAPACITY_DATA_ADD";
export const CAPACITY_COLUMN_ADD = "CAPACITY_COLUMN_ADD";

export const CAPACITY_DATA_CHANGE = "CAPACITY_DATA_CHANGE";
export const CAPACITY_DATA_UPDATE = "CAPACITY_DATA_UPDATE";
export const CAPACITY_DATE_ROW_CHANGE = "CAPACITY_DATE_ROW_CHANGE";

export const CAPACITY_EMPTY = "CAPACITY_EMPTY";

export const CAPACITY_UPDATE_SUCCESS = "CAPACITY_SUCCESS";
export const CAPACITY_UPDATE_ERROR = "CAPACITY_ERROR";
export const CAPACITY_UPDATE_PROCESS = "CAPACITY_PROCESS";

export const CAPACITY_FOCUS = "CAPACITY_FOCUS";
export const CAPACITY_ERROR = "CAPAPCITY_ERROR";
export const CAPACITY_CLEAR = "CAPACITY_CLEAR";

// SAGA
export const capacityYearData = (data) => ({ type: YEAR_ADD, data });
export const capacityPeriodData = (data) => ({ type: PERIOD_ADD, data });
export const capacityPeriodSelect = (selected) => ({
  type: PERIOD_SELECT,
  selected: selected || "",
});

export const capacitySOData = (data) => ({ type: CAPACITY_DATA_ADD, data });
export const capacitySOColumn = (data) => ({ type: CAPACITY_COLUMN_ADD, data });

// INDEX
export const YearFetch = () => ({ type: YEAR_FETCH });
export const capacityYearSelect = (selected) => ({
  type: CAPACITY_YEAR_SELECT,
  selected,
});
export const periodFetch = (year) => {
  return { type: PERIOD_FETCH, year };
};
export const capacityFetch = (periodID) => ({
  type: CAPACITY_DATA_FETCH,
  periodID,
});

export const capacitySOEmpty = () => ({ type: CAPACITY_EMPTY });

export const capacityDataChange = (index, key, value, UsedFor, oldValue) => ({
  type: CAPACITY_DATA_CHANGE,
  index,
  key,
  value,
  UsedFor,
  oldValue,
});

export const capacityDataUpdate = (data) => ({
  type: CAPACITY_DATA_UPDATE,
  data,
});

export const capacityUpdateSuccess = () => ({ type: CAPACITY_UPDATE_SUCCESS });
export const capacityUpdateError = () => ({ type: CAPACITY_UPDATE_ERROR });
export const capacityUpdateProcess = () => ({ type: CAPACITY_UPDATE_PROCESS });

export const capacityError = () => ({ type: CAPACITY_ERROR });
