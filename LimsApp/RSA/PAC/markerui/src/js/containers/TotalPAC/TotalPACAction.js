export const TOTALPAC_COLUMN_ADD = 'TOTALPAC_COLUMN_ADD';
export const totalPACColumnAdd = data => ({
  type: TOTALPAC_COLUMN_ADD,
  data
});
export const TOTALPAC_EMPTY = 'TOTALPAC_EMPTY';
export const totalPACEmpty = () => ({
  type: TOTALPAC_EMPTY
});

export const TOTALPAC_DATA_ADD = 'TOTALPAC_DATA_ADD';
export const totalPACDataAdd = data => ({
  type: TOTALPAC_DATA_ADD,
  data
});

export const TOTALPAC_TOTAL = 'TOTALPAC_TOTAL';
export const totalPACTotal = total => ({
  type: TOTALPAC_TOTAL,
  total
});

export const TOTALPAC_PAGE = 'TOTALPAC_PAGE';
export const totalPACPage = page => ({
  type: TOTALPAC_PAGE,
  page
});

export const FETCH_PAGE = 'FETCH_PAGE';
export const fetchPage = (page, size, sortBy, sortOrder, filter) => ({
  type: FETCH_PAGE,
  page, size,
  sortBy, sortOrder,
  filter
});

export const EXPORT_PAGE = 'EXPORT_PAGE';
export const exportPage = filter => ({
  type: EXPORT_PAGE,
  filter
});

export const TOTALPAC_FILTER_ADD = 'TOTALPAC_FILTER_ADD';
export const totalPACFilter = obj => ({
  type: TOTALPAC_FILTER_ADD,
  data: obj
});

export const TOTALPAC_SORTER_ADD = 'TOTALPAC_SORTER_ADD';
export const totalPACSorter = obj => ({
  type: TOTALPAC_SORTER_ADD,
  data: obj
});
