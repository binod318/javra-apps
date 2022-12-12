import { connect } from 'react-redux';
import CTMaintainComponent from './ctMaintainComponent';

import './ctmmanagment.scss';

const mapState = state => ({
  sideMenu: state.sidemenuReducer,
  process: state.ctMaintain.process,
  location: state.ctMaintain.location,
  startMaterial: state.ctMaintain.startMaterial,
  typeCT: state.ctMaintain.type
});
const mapDispatch = dispatch => ({
  fetchProcess: () => {
    dispatch({ type: 'CT_PROCESS_FETCH' });
  },
  postProcess: obj => {
    dispatch({ type: 'CT_PROCESS_POST', ...obj });
  },
  fetchLabLocation: () => {
    dispatch({ type: 'CT_LABLOCATIONS_FETCH' });
  },
  postLabLocation: obj => {
    dispatch({ type: 'CT_LABLOCATIONS_POST', ...obj });
  },
  fetchStartMaterial: () => {
    dispatch({ type: 'CT_STARTMATERIAL_FETCH' });
  },
  postStartMaterial: obj => {
    dispatch({ type: 'CT_STARTMATERIAL_POST', ...obj });
  },
  fetchTypeCt: () => {
    dispatch({ type: 'CT_TYPE_FETCH' });
  },
  postTypeCT: obj => {
    dispatch({ type: 'CT_TYPE_POST', ...obj });
  }
});
export default connect(
  mapState,
  mapDispatch
)(CTMaintainComponent);
