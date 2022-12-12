export const YEAR_FETCH = 'YEAR_FETCH';
export const YEAR_ADD = 'YEAR_ADD';
export const LAB_YEAR_SELECT = 'LAB_YEAR_SELECT';

export const LAB_DATA_FETCH = 'LAB_DATA_FETCH';
export const LAB_DATA_ADD = 'LAB_DATA_ADD';
export const LAB_COLUMN_ADD = 'LAB_COLUMN_ADD';
export const LAB_DATA_CHANGE = 'LAB_DATA_CHANGE';
export const LAB_DATA_UPDATE = 'LAB_DATA_UPDATE';
export const LAB_DATE_ROW_CHANGE = 'LAB_DATE_ROW_CHANGE';
export const LAB_EMPTY = 'LAB_EMPTY';

export const LAB_UPDATE_SUCCESS = 'LAB_SUCCESS';
export const LAB_UPDATE_ERROR = 'LAB_ERROR';

// SAGA
export const labYearData = data => ({ type: YEAR_ADD, data });
export const labYearSelect = selected => ({ type: LAB_YEAR_SELECT, selected });
export const labCapacityData = data => ({ type: LAB_DATA_ADD, data });
export const labCapacityColumn = data => ({ type: LAB_COLUMN_ADD, data });

// INDEX
export const YearFetch = () => ({ type: YEAR_FETCH });
export const labFetch = year => ({ type: LAB_DATA_FETCH, year });
export const labDataChange = (index, key, value) => ({
  type: LAB_DATA_CHANGE,
  index,
  key,
  value
});
export const labDataRowChange = (key, value) => ({
  type: LAB_DATE_ROW_CHANGE,
  key,
  value
});
export const labDataUpdate = (data, year) => ({
  type: LAB_DATA_UPDATE,
  data,
  year
});

export const labUpdateSuccess = () => ({ type: LAB_UPDATE_SUCCESS });
export const labUpdateError = () => ({ type: LAB_UPDATE_ERROR });
