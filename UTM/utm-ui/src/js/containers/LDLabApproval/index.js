import { connect } from 'react-redux';
import LDLabApprovalComponent from './components/LDLabApprovalComponent';
import {
  getLDApprovalList,
  getLDPlanPeriods,
  approveLDSlot as approveLDSlotAction,
  denyLDSlot as denyLDSlotAction
} from './actions';
import { locationFetch } from "../../action"
import { sidemenuClose } from '../../action';
import './index.scss';

const mapStateToProps = state => ({
  current: state.ldApprovalList.current,
  standard: state.ldApprovalList.standard,
  details: state.ldApprovalList.details,
  columns: state.ldApprovalList.columns,
  planPeriods: state.ldPlanPeriods,
  location: state.location 
});
const mapDispatchToProps = {
  sidemenu: sidemenuClose,
  getLDApprovalList,
  getLDPlanPeriods,
  approveLDSlot: approveLDSlotAction,
  denyLDSlot: denyLDSlotAction,
  locationFetch,
};

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(LDLabApprovalComponent);
