export const processing = () => ({ type: 'FETCHING_RELATION_PROCESSING' });
export const success = message => ({
  type: 'FETCHING_RELATION_SUCCESS',
  message
});
export const error = (from, message) => ({
  type: 'FETCHING_RELATION_ERROR',
  message,
  from
});

export const getResults = (pageNumber, pageSize, filter, sorting) => ({
  type: 'GET_RESULT',
  pageNumber,
  pageSize,
  filter,
  sorting
});

export const getTrait = (traitName, cropCode) => ({
  type: 'TRAITS_GET',
  traitName,
  cropCode
});

export const getTraitList = traitID => ({
  type: 'TRAITLIST_GET',
  traitID
});

export const getScreeningList = screeningFieldID => ({
  type: 'SCREENINGLIST_GET',
  screeningFieldID
});

export const filterAdd = obj =>
  Object.assign({}, obj, { type: 'FILTER_TRAITRESULT_ADD' });
export const filterRemove = name => ({
  type: 'FILTER_TRAITRESULT_REMOVE',
  name
});
export const filterClear = () => ({
  type: 'FILTER_TRAITRESULT_CLEAR'
});



export const postData = data => ({
  type: 'ATTRIBUTE_SAVE',
  data
});



export const getCheckValidation = source => ({
  type: 'getCheckValidation',
  source
});


// saga
export const storeResult = data => ({
  type: 'RESULT_BULK',
  data
});

export const storeSort = (name, direction) => ({
  type: 'RESULT_SORT',
  name,
  direction
});

export const storeTotal = total => ({
  type: 'RESULT_TOTAL',
  total
});

export const storePage = pageNumber => ({
  type: 'RESULT_PAGE',
  pageNumber
});

export const traitsAdd = data => ({
  type: 'TRAITS_ADD',
  data
});

export const traitListAdd = data => ({
  type: 'TRAITLIST_ADD',
  data
});

export const screeningListAdd = data => ({
  type: 'SCREENINGLIST_ADD',
  data
});

export const resultError = message => ({
  type: 'RESULT_ADD_ERROR',
  message
});

export const cropBulk = crops => ({
  type: 'CROPS_BULK',
  crops
});
