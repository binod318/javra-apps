export const mailProcessing = () => ({ type: 'MAIL_PROCESSING' });
export const mailSuccess = message => ({ type: 'MAIL_SUCCESS', message });
export const mailError = message => ({ type: 'MAIL_ERROR', message });

export const fetchCropData = () => ({ type: 'FETCH_CROPS' });
export const resetError = () => ({ type: 'RESET_ERROR'});

export const fetchMailData = (pageNumber, pageSize) => ({
  type: 'GET_MAIL',
  pageNumber,
  pageSize
});

export const postMailData = (configID, configGroup, cropCode, recipients) => ({
  type: 'POST_MAIL',
  configID, configGroup, cropCode, recipients
});

export const deleteMailData = configID => ({
  type: 'DELETE_MAIL',
  configID
});

// SAGA
export const mailBulk = data => ({
  type: 'MAIL_BULK',
  data
});
export const mailRecords = total => ({
  type: 'MAIL_RECORDS',
  total
});
export const mailRefresh = () => ({ type: 'MAIL_REFRESH' });
