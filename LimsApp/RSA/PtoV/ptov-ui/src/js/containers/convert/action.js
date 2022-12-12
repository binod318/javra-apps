export const convertProcessing = () => ({ type: 'CONVERT_PROCESSING' });
export const convertSuccess = () => ({ type: 'CONVERT_SUCCESS' });
export const convertError = message => ({ type: 'CONVERT_ERROR', message });

export const unmapProcessing = () => ({ type: 'UNMAP_PROCESSING' });
export const unmapSuccess = message => ({ type: 'UNMAP_SUCCESS', message });
export const unmapError = message => ({ type: 'UNMAP_ERROR', message });

export const convertFetch = (fileName, pageNumber, pageSize, filter, sorting) => ({
  type: 'FETCH_CONVERT',
  fileName,
  pageNumber,
  pageSize,
  filter,
  sorting
});
export const convertImportPhenome = (objectType, objectID, cropID, pageSize) => ({
  type: 'IMPORT_PHENOME',
  objectType,
  objectID,
  cropID,
  pageSize
});
export const convertFilterAdd = obj => ({
  type: 'FILTER_CONVERT_ADD',
  ...obj
});
export const convertFilterRemove = name => ({
  type: 'FILTER_CONVERT_REMOVE',
  name
});
export const convertFilterClear = () => ({
  type: 'FILTER_CONVERT_CLEAR'
});
export const convertColumnRemove = column => ({
  type: 'CONVERT_COL_DELETION',
  column
});

export const convertBluk = data => ({
  type: 'CONVERT_BULK',
  data
});
export const convertColumn = data => ({
  type: 'CONVERT_COL_BULK_ADD',
  data
});
export const convertTotal = total => ({
  type: 'CONVERT_RECORDS',
  total
});
export const convertSize = pageSize => ({
  type: 'CONVERT_SIZE',
  pageSize
});
export const convertPage = pageNumber => ({
  type: 'CONVERT_PAGE',
  pageNumber
});
export const convertSort = (name, direction) => ({
  type: 'CONVERT_SORT',
  name,
  direction
});
