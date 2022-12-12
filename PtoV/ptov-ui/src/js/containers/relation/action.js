export const relationProcessing = () => ({
  type: 'FETCHING_RELATION_PROCESSING'
});
export const relationSuccess = () => ({ type: 'FETCHING_RELATION_SUCCESS' });
export const relationError = (from, message) => ({
  type: 'FETCHING_RELATION_ERROR',
  message,
  from
});
export const updateProcessing = () => ({
  type: 'FETCHING_RELATION_UPDATE_PROCESSING'
});
export const updateSuccess = () => ({
  type: 'FETCHING_RELATION_UPDATE_SUCCESS'
});
export const updateError = message => ({
  type: 'FETCHING_RELATION_UPDATE_ERROR',
  message
});

//
export const fetchRelation = (pageNumber, pageSize, filter, sorting) => ({
  type: 'GET_RELATION',
  pageNumber,
  pageSize,
  filter,
  sorting
});

export const postRelation = data => ({
  type: 'POST_RELATION',
  data
});

export const filterAdd = obj =>
  Object.assign({}, obj, { type: 'FILTER_TRAIT_ADD' });
export const filterRemove = name => ({
  type: 'FILTER_TRAIT_REMOVE',
  name
});
export const filterClear = () => ({ type: 'FILTER_TRAIT_CLEAR' });

export const fetchDetermination = (determinationName, cropCode) => ({
  type: 'FETCH_DETERMINATION',
  determinationName,
  cropCode
});

export const storeSort = (name, direction) => ({
  type: 'TRAIT_SORT',
  name,
  direction
});

export const storeDetermination = data => ({
  type: 'DETERMINATION_ADD',
  data
});

export const storeRelation = data => ({
  type: 'RELATION_BULK',
  data
});

export const storeTotal = total => ({
  type: 'TRAIT_RECORDS',
  total
});
export const storePage = pageNumber => ({
  type: 'TRAIT_PAGE',
  pageNumber
});
