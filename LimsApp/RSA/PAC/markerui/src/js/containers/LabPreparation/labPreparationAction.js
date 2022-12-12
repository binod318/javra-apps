import { YEAR_FETCH } from '../CapacitySO/capacitySOAction';
export const LABPREPARATION_YEAR_SELECT = 'LABPREPARATION_YEAR_SELECT';

export const YEAR_ADD = 'YEAR_ADD';
export const LABPREPARATION_PEROID_FETCH = 'LABPREPARATION_PERIOND_FETCH';
export const LABPREPARATION_PERIOD_ADD = 'LABPREPARATION_PERIOD_ADD';
export const LABPREPARATION_PERIOD_SELECT = 'LABPREPARATION_PERIOD_SELECT';
export const LABPREPARATION_PERIOD_BLANK = 'LABPREPARATION_PERIOD_BLANK';

export const LABPREPARATION_FOLDER_FETCH = 'LABPREPARATION_FOLDER_FETCH';



export const YearFetch = () => ({ type: YEAR_FETCH });
export const labPreparationYearSelected = selected => ({
  type: LABPREPARATION_YEAR_SELECT,
  selected
});

export const labPreparationPeriodFetch = year => ({ type: LABPREPARATION_PEROID_FETCH, year });
export const labPreparationPeriodBlank = () => ({ type: LABPREPARATION_PERIOD_BLANK });
export const labPreparationPeriodSelected = selected => ({
  type: LABPREPARATION_PERIOD_SELECT,
  selected
});

export const labPreparationFolderFetch = periodID => ({
  type: LABPREPARATION_FOLDER_FETCH,
  periodID
});
// GROUP
export const LABPREPARATION_GROUP_ADD = 'LABPREPARATION_GROUP_ADD';
export const labPreparationGroupAdd = data => ({
  type: LABPREPARATION_GROUP_ADD,
  payload: data
});
export const LABPREPARATION_GROUP_TOGGLE = 'LABPREPARATION_GROUP_TOGGLE';
export const labPreparationGroupToggle = index => ({
  type: LABPREPARATION_GROUP_TOGGLE,
  payload: index
});

// GRID DATA
export const LABPREPARATION_DATA_ADD = 'LABPREPARATION_DATA_ADD';
export const labPreparationDataAdd = data => ({
  type: LABPREPARATION_DATA_ADD,
  payload: data
});

export const LABPREPARATION_COLUMN_ADD = 'LABPREPARATION_COLUMN_ADD';
export const labPreparationColumnAdd = data => ({
  type: LABPREPARATION_COLUMN_ADD,
  payload: data
});

export const LABPREPARATION_EMPTY = 'LABPREPARATION_EMPTY';
export const labPreparationEmpty = () => ({
  type: LABPREPARATION_EMPTY,
  payload: []
});


// LABDECLUSTER_FETCH
export const LABDECLUSTER_FETCH = 'LABDECLUSTER_FETCH';
export const labDeclusterFetch = (periodID, detAssignmentID) => ({
  type: LABDECLUSTER_FETCH,
  periodID,
  detAssignmentID
});
export const LABDECLUSTER_COLUMN_ADD = 'LABDECLUSTER_COLUMN_ADD';
export const labDeclusterColumnAdd = data => ({
  type: LABDECLUSTER_COLUMN_ADD,
  payload: data
});
export const LABDECLUSTER_DATA_ADD = 'LABDECLUSTER_DATA_ADD';
export const labDeclusterDataAdd = data => ({
  type: LABDECLUSTER_DATA_ADD,
  payload: data
});

export const LAB_TEST_SET_STATUS = 'LAB_TEST_SET_STATUS';
export const  labTestSetStatus = StatusCode => ({
  type: LAB_TEST_SET_STATUS,
  StatusCode
});

export const LAB_TEST_SET_DA_STATUS = 'LAB_TEST_SET_DA_STATUS';
export const  labTestSetDAStatus = StatusCode => ({
  type: LAB_TEST_SET_DA_STATUS,
  StatusCode
});

export const PLANNING_PRINT_PLATE_LABEL = 'PLANNING_PRINT_PLATE_LABEL';
export const printPlateLabel = (PeriodID, TestID) => ({
  type: PLANNING_PRINT_PLATE_LABEL,
  PeriodID, TestID
});

export const LAB_SET_FILLRATE_TOTALUSED = 'LAB_SET_FILLRATE_TOTALUSED';
export const  labSetFillRateTotalUsed = TotalUsed => ({
  type: LAB_SET_FILLRATE_TOTALUSED,
  TotalUsed
});

export const LAB_SET_FILLRATE_TOTALRESERVED = 'LAB_SET_FILLRATE_TOTALRESERVED';
export const  labSetFillRateTotalReserved = TotalReserved => ({
  type: LAB_SET_FILLRATE_TOTALRESERVED,
  TotalReserved
});
