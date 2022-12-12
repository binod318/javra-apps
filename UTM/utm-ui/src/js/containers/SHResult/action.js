export const getResults = (pageNumber, pageSize, filter) => ({
  type: 'GET_SH_RESULT',
  pageNumber,
  pageSize,
  filter
});


export const getTraitValues = cropTraitID => ({
  type: 'FETCH_TRAITVALUES',
  cropTraitID
});

export const postData = data => ({
  type: 'POST_SH_RESULT',
  data
});

export const resetFilter = () => ({
  type: 'FILTER_SH_RESULT_CLEAR'
});

export const getCheckValidation = source => ({
  type: 'getCheckValidation',
  source
});
export const resetCheckValidation = () => ({
  type: 'CHECKVALIDATION_RESET'
});

// notification
export const showNotification = (message, messageType, code) => ({
  type: 'NOTIFICATION_SHOW',
  status: true,
  message,
  messageType,
  notificationType: 0,
  code: code || ''
});

// saga
export const storeSHResult = data => ({
  type: 'SH_RESULT_BULK',
  data
});

export const storeAppend = data => ({
  type: 'RESULT_ADD',
  data
});

export const storeCheckValidtion = data => ({
  type: 'CHECKVALIDATION_BULK',
  data
});

export const storeSHTotal = total => ({
  type: 'SH_RESULT_RECORDS',
  total
});

export const storeSHPage = pageNumber => ({
  type: 'SH_RESULT_PAGE',
  pageNumber
});

export const SHResultFilterBluk = filter => ({
  type: 'FILTER_SH_RESULT_ADD_BLUK',
  filter
});
