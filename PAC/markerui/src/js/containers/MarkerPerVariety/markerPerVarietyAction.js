export const MARKER_PER_VARIETY_FETCH = 'MARKER_PER_VARIETY_FETCH';
export const markerPerVarietyFetch = (page, size, sortBy, sortOrder, filter) => ({ 
  type: MARKER_PER_VARIETY_FETCH,
  page, 
  size,
  sortBy, 
  sortOrder,
  filter
});

export const MARKERPERVARIETY_COLUMN_ADD = 'MARKERPERVARIETY_COLUMN_ADD';
export const markerPerVarietyColumnAdd = data => ({
  type: MARKERPERVARIETY_COLUMN_ADD,
  data
});

export const MARKERPERVARIETY_DATA_ADD = 'MARKERPERVARIETY_DATA_ADD';
export const markerPerVarietyDataAdd = data => ({
  type: MARKERPERVARIETY_DATA_ADD,
  data
});

export const GET_MARKER_FETCH = 'GET_MARKER_FETCH';
export const getMarkersFetch = (markerName, cropCode, showPacMarkers) => ({ type: GET_MARKER_FETCH, markerName, cropCode, showPacMarkers });

export const MARKER_DATA = 'MARKER_DATA';

export const GET_VARIETIES_FETCH = 'GET_VARIETIES_FETCH';
export const getVarietiesFetch = (varietyName, cropCode) => ({ type: GET_VARIETIES_FETCH, varietyName, cropCode });

export const VARIETIES_DATA = 'VARIETIES_DATA';

export const GET_CROPS_FETCH = 'GET_CROPS_FETCH';
export const getCropsFetch = () => ({ type: GET_CROPS_FETCH });

export const CROPS_DATA = 'CROPS_DATA';

export const POST_MARKERPERVARIETY = 'POST_MARKERPERVARIETY';
export const postMarkerPerVariety = (MarkerPerVarID, MarkerID, VarietyNr, Remarks, ExpectedResult, action) => ({
  type: POST_MARKERPERVARIETY,
  MarkerPerVarID, MarkerID, VarietyNr, Remarks, ExpectedResult, action
});

export const MARKERPERVARIETY_EMPTY = 'MARKERPERVARIETY_EMPTY';
export const markerPerVarietyEmpty = () => ({
  type: MARKERPERVARIETY_EMPTY
});

export const MARKERPERVARIETY_TOTAL = 'MARKERPERVARIETY_TOTAL';
export const markerPerVarietyTotal = total => ({
  type: MARKERPERVARIETY_TOTAL,
  total
});

export const MARKERPERVARIETY_PAGE = 'MARKERPERVARIETY_PAGE';
export const markerPerVarietyPage = page => ({
  type: MARKERPERVARIETY_PAGE,
  page
});

export const MARKERPERVARIETY_PAGESIZE = 'MARKERPERVARIETY_PAGESIZE';
export const markerPerVarietyPageSize = pageSize => ({
  type: MARKERPERVARIETY_PAGESIZE,
  pageSize
});

export const MARKERPERVARIETY_FILTER_ADD = 'MARKERPERVARIETY_FILTER_ADD';
export const markerPerVarietyFilter = obj => ({
  type: MARKERPERVARIETY_FILTER_ADD,
  data: obj
});