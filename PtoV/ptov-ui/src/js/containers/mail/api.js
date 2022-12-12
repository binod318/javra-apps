import axios from 'axios';
import URLS from '../../urls';

// FETCH
export const getMailApi = (pageNumber, pageSize) =>
  axios({
    method: 'get',
    url: URLS.getEmailConfig,
    params: {
      pageNumber,
      pageSize
    }
  });

export const postMailApi = (configID, configGroup, cropCode, recipients) =>
  axios({
    method: 'post',
    url: URLS.postEmailConfig,
    data: {
      configID,
      cropCode,
      configGroup,
      recipients
    }
  });

export const deleteMailApi = (configID) =>
  axios({
    method: 'delete',
    url: URLS.deletEmailConfig,
    data: {
      configID
    }
  });
