import { combineReducers } from 'redux';
import sidemenuReducer from '../components/Aside/reducer';
import loader from '../components/Loader/reducer';
import notification from '../components/Notification/reducer';
import remarks from '../components/Remarks/remarkReducer';
import sources from './sources';
import exportList from '../containers/Home/compoments/Export/reducer';
import assignMarker from '../containers/Home/reducers/index';
import phenome from '../containers/Home/reducers/phenome';
import plateFilling from '../containers/PlateFilling/reducers/index';
import statusList from './statusList';
import getWellTypeID from './getWellTypeID';
import materialType from './materialType';
import testProtocol from './testProtocol';
import materialState from './materialState';
import containerType from './containerType';

import breedingStation from './breedingStation';

import slot from '../components/Slot/reducers';
import user from './user';
import location from './location';
// Breeder
import breeder from '../containers/Breeder/reducers';
// Breeder
import leafDiskCapacityPlanning from '../containers/LeafDiskCapacityPlanning/reducers';
// lab
import lab from '../containers/Lab/reducers';
import ldLabCapacity from '../containers/LDlabCapacity/reducers';
import approvalList from '../containers/LabApproval/reducers/approvalList';
import planPeriods from '../containers/LabApproval/reducers/planPeriods';
import ldApprovalList from '../containers/LDLabApproval/reducers/ldApprovalList';
import ldPlanPeriods from '../containers/LDLabApproval/reducers/ldPlanPeriods';
import laboverview from '../containers/LabOverview/reducers/index';
import ldlaboverview from '../containers/LDLabOverview/reducers/index';
import ldOverview from '../containers/LDOverview/reducers';

//seed health
import shOverview  from '../containers/SHOverview/reducers';
import shResult from '../containers/SHResult/reducer';

import slotBreeder from '../containers/BreederOverview/reducer';

import traitRelation from '../containers/Trait/reducerTrait';
import traitResult from '../containers/TraitResult/reducer';
import mailResult from '../containers/Mail/mailReducer';
import platPlan from '../containers/PlatPlan/reducer';

import rdtoverview from '../containers/RDTOverview/reducers';
import rdtResult from '../containers/RdtResult/reducer';

import labProtocol from '../containers/LabProtocol/reducer';

import ctMaintain from '../containers/CTMaintain/CTMaintainReducer';

const ini = {
  testID: null,
  testTypeID: null,
  statusCode: null,
  remark: '',
  remarkRequired: null,
  slotID: null,
  wellsPerPlate: null,
  platePlanName: '',
  importLevel: 'PLT'
};
const rootTestID = (state = ini, action) => {
  switch (action.type) {
    /*        case "ROOT_TESTID":
     console.log('rootID root index', action.rootID);
     return action.rootID; */
    case 'ROOT_SET_ALL':
      return Object.assign({}, state, {
        testID: action.testID,
        testTypeID: action.testTypeID,
        statusCode: action.statusCode,
        statusName: action.statusName,
        remark: action.remark,
        remarkRequired: action.remarkRequired,
        slotID: action.slotID,
        platePlanName: action.platePlanName || '',
        importLevel: action.importLevel || 'PLT'
      });
    case 'ROOT_TESTID':
      return Object.assign({}, state, { testID: action.testID });
    case 'ROOT_SLOTID':
      return Object.assign({}, state, { slotID: action.slotID });
    case 'ROOT_TESTTYPEID':
      return Object.assign({}, state, { testTypeID: action.testTypeID });
    case 'ROOT_STATUS':
      return Object.assign({}, state, { statusCode: action.statusCode });
    case 'ROOT_STATUS_NAME':
      return Object.assign({}, state, { statusName: action.statusName });
    case 'ROOT_WELL_SIZE':
      return Object.assign({}, state, { wellsPerPlate: action.wellsPerPlate });
    case 'ROOT_REMARK':
      return Object.assign({}, state, { remark: action.remark });
    case 'ROOT_REMARKREQUIRED':
      return Object.assign({}, state, {
        remarkRequired: action.remarkRequired
      });
    /*        case 'ROOT_TESTTYPENAME':
     return Object.assign({}, state, {testTypeName: action.testTypeName}); */
    case 'RESETALL_PLATEFILLING':
    case 'RESETALL':
      return ini;
    case 'ROOT_SET_REMARK':
    default:
      return state;
  }
};

const pageTitle = (state = '', action) => {
  switch (action.type) {
    case 'SET_PAGETITLE':
      return action.title;
    case 'RESETALL':
      return '';
    default:
      return state;
  }
};

const selectedMenu = (state = '', action) => {
  switch (action.type) {
    case 'SET_SELECTEDMENU':
      return action.menu;
    default:
      return state;
  }
};

const rootReducer = combineReducers({
  rdtoverview,
  rdtResult,
  pageTitle,

  loader,
  notification,
  sidemenuReducer,
  user,
  location,
  breedingStation,

  rootTestID,
  statusList,
  remarks,
  slot,

  sources,
  exportList,

  assignMarker,
  materialType,
  testProtocol,
  materialState,
  containerType,

  plateFilling,
  getWellTypeID,

  slotBreeder,

  lab,
  ldLabCapacity,
  laboverview,
  ldlaboverview,
  approvalList,
  planPeriods,
  breeder,
  leafDiskCapacityPlanning,
  phenome,
  ldApprovalList,
  ldPlanPeriods,
  ldOverview,

  shOverview,
  shResult,

  traitRelation,
  traitResult,
  mailResult,

  platPlan,
  labProtocol,

  ctMaintain,
  selectedMenu
});
export default rootReducer;
