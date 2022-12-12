export const getResults = (pageNumber, pageSize, filter) => ({
  type: 'GET_RDT_RESULT',
  pageNumber,
  pageSize,
  filter
});


// export const getTraitValues = (cropCode, traitID) => ({
export const getTraitValues = cropTraitID => ({
  type: 'FETCH_TRAITVALUES',
  cropTraitID
});

export const postData = data => ({
  type: 'POST_RDT_RESULT',
  data
});

export const traitValuesReset = () => ({
  type: 'TRAITVALUE_RESET'
});

export const resetFilter = () => ({
  type: 'FILTER_RDT_RESULT_CLEAR'
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
export const storeRDTResult = data => ({
  type: 'RDT_RESULT_BULK',
  data
});

export const storeAppend = data => ({
  type: 'RESULT_ADD',
  data
});

export const storeTraitValues = data => ({
  type: 'TRAITVALUE_BULK',
  data
});

export const storeCheckValidtion = data => ({
  type: 'CHECKVALIDATION_BULK',
  data
});

export const storeRDTTotal = total => ({
  type: 'RDT_RESULT_RECORDS',
  total
});

export const storeRDTPage = pageNumber => ({
  type: 'RDT_RESULT_PAGE',
  pageNumber
});

export const RDTResultFilterBluk = filter => ({
  type: 'FILTER_RDT_RESULT_ADD_BLUK',
  filter
});
