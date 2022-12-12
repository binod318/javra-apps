import { connect } from 'react-redux';
import MailComponent from './components/MailComponent';
import {
  dMailConfigFetch,
  dMailConfigAppend,
  dMailCconfigDestory
} from './mailAction';

const mapState = state => ({
  sideMenu: state.sidemenuReducer,
  email: state.mailResult.data,
  total: state.mailResult.total.total,
  pagenumber: state.mailResult.total.pageNumber,
  pagesize: state.mailResult.total.pageSize,
  refresh: state.mailResult.total.refresh,
  breedingStation: state.breedingStation.station,
  filter: state.mailResult.filter,
  selectedMenu: state.selectedMenu
});
const mapDispatch = dispatch => ({
  fetchMail: (pageNumber, pageSize, usedForMenu) =>
    dispatch(dMailConfigFetch(pageNumber, pageSize, usedForMenu)),
  addMailFunc: (configID, cropCode, configGroup, recipients, brStationCode, usedForMenu) => {
    dispatch(
      dMailConfigAppend(
        configID,
        cropCode,
        configGroup,
        recipients,
        brStationCode,
        usedForMenu
      )
    );
  },
  editMailFunc: (
    configID,
    cropCode,
    configGroup,
    recipients,
    brStationCode,
    usedForMenu
  ) => {
    dispatch(
      dMailConfigAppend(
        configID,
        cropCode,
        configGroup,
        recipients,
        brStationCode,
        usedForMenu
      )
    );
  },
  deleteMailFunction: (configID, usedForMenu) => dispatch(dMailCconfigDestory(configID, usedForMenu)),
  fetchBreeding: () => dispatch({ type: 'FETCH_BREEDING_STATION' }),
  filterAdd: obj =>
    dispatch({ type: "FILTER_MAIL_ADD_BLUK", filter: obj }),
  filterClear: () => dispatch({ type: "FILTER_MAIL_CLEAR" }),
});
export default connect(
  mapState,
  mapDispatch
)(MailComponent);
