/*!
 *
 * MAIL CONFIG
 * ------------------------------
 * Normal email validation
 * 1. Add mail you can select crop and input email. (not group);
 * 2. Edit, you can edit mail list.
 * 3. Delete existing email config.
 *
 */
import { connect } from 'react-redux';
import Mail from './mail';
import {
  fetchMailData, postMailData, deleteMailData,
  resetError, mailError, fetchCropData
} from './action';

const mapState = state => ({
  status: state.status,
  mail: state.mail.mail,
  total: state.mail.total.total,
  pagenumber: state.mail.total.pageNumber,
  pagesize: state.mail.total.pageSize,
  refresh: state.mail.refresh,
  crops: state.result.crops
});

const mapDispatch = dispatch => ({
  fetchData: (pageNumber, pageSize) => dispatch(fetchMailData(pageNumber, pageSize)),
  fetchCrops: () => dispatch(fetchCropData()),
  postData: (configID, configGroup, cropCode, recipients) => dispatch(postMailData(configID, configGroup, cropCode, recipients)),
  deleteData: configID => dispatch(deleteMailData(configID)),
  resetError: () => dispatch(resetError()),
  mailError: message => dispatch(mailError(message)),
})

export default connect(
  mapState,
  mapDispatch
)(Mail);
