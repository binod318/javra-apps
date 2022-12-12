import {
  all,
  call,
  put,
  takeLatest,
  select,
  race,
  take
} from "redux-saga/effects"; // take, takeEvery, delay
import axios from "axios";
import urlConfig from "../urlConfig";

import {
  watchFetchGetExternalTests,
  watchExportTest
} from "../containers/Home/compoments/Export/saga";

import {
  watchGetSlotList,
  watchPostLinkSlotTest
} from "../components/Slot/saga";
import {
  watchsaveConfigName
} from "../components/SaveDialogue/saga";
import {
  watchFetchMaterials,
  watchFetchMaterialsWithDeterminationsForExternalTest,
  watchUpdateTestAttributesDispatch,
  watchFetchFilteredMaterials,
  watchSaveMaterialMarker,
  watchAssignMarker,
  watchAddToThreeGB,
  watchFetchThreeGB,
  watchSave3GBmarker,
  watchFetchLeafDiskSampleData,
  watchSaveSample,
  watchFetchSamples,
  watchAddMaterialsToSample,
  watchFetchMaterialDeterminations,
  watchfetchLeafDiskDeterminations,
  watchAssignLDDeterminations,
  watchSaveLDDeterminationsChanged,
  watchUpdateTestMaterial,
  watchDeleteSample,

  watchFetchSeedHealthSampleData,
  watchFetchSHMaterialDeterminations,
  watchfetchSeedHealthDeterminations,
  watchSaveSHDeterminationsChanged,
  watchAssignSHDeterminations,
  watchSHDeleteSample,
  watchExportToExcelSH,
  watchSendToABSSH
} from "./assignMarkerSagas";

// fetchWellType, wetchStatusList,
import {
  watchCreateReplicaDispatch,
  watchDeleteDeadMaterialsDispatch,
  watchFetchStatusList,
  watchFetchPlateData,
  watchDeleteRow,
  fetchPlateDataApi,
  watchActionSaveDB,
  watchReservePlate,
  watchUndoDead,
  watchDeleteReplicate,
  watchUndoFixedPosition,
  watchFetchWellType,
  watchFetchWell,
  watchPlateFillingExcel,
  watchPlateFillingTotalMarker
} from "../containers/PlateFilling/saga";
import { fetchAssignFilterDataApi } from "../containers/Home/api";
import {
  watchBreeder,
  watchCropChange,
  watchBreederReserve,
  watchPeriod,
  watchPlantsTests,
  watchSlotDelete,
  watchSlotEdit
} from "../containers/Breeder/saga";
import {
  watchLeafDiskCapacityPlanning,
  watchLeafDiskCapacityPlanningCropChange,
  watchLeafDiskCapacityPlanningReserve,
  watchLeafDiskCapacityPlanningPeriod,
  watchLeafDiskCapacityPlanningAvailableSample,
  watchLeafDiskCapacityPlanningSlotDelete,
  watchLeafDiskCapacityPlanningSlotEdit,
  watchLeafDiskFetchSlot,
  watchExportCapacityPlanningLeafDisk
} from "../containers/LeafDiskCapacityPlanning/saga";
import {
  watchPlanningCapacity,
  watchPlanningUpdate
} from "../containers/Lab/saga";
import {
  watchLDplanningCapacity,
  watchLDplanningUpdate
} from "../containers/LDlabCapacity/saga";
import {
  watchLabOverview,
  watchLabOverviewExcel,
  watchLabSlotEdit
} from "../containers/LabOverview/saga";
import {
  watchLDLabOverview,
  watchLDLabOverviewExcel,
  watchLDLabSlotEdit
} from "../containers/LDLabOverview/saga";
import {
  watchGetApprovalList,
  watchGetPlanPeriods,
  watchSlotApproval,
  watchSlotDenial,
  watchUpdateSlotPeriod
} from "../containers/LabApproval/saga";
import {
  watchGetLDApprovalList,
  watchGetLDPlanPeriods,
  watchLDSlotApproval,
  watchLDSlotDenial,
  watchUpdateLDSlotPeriod
} from "../containers/LDLabApproval/saga";

import {
  noInternet,
  // notificationSuccess,
  notificationMsg,
  notificationSuccessTimer
} from "./notificationSagas";
// notificationGeneric

import {
  phenomeLogin,
  getResearchGroups,
  getFolders,
  importPhenome,
  getBGAvailableProjects,
  sendToThreeGBCockpit,
  getS2SCapacity,
  fetchPhenomToken
} from "../containers/Home/saga/phenome";

import {
  watchFetchSlot,
  watchExportCapacityPlanning
} from "../containers/BreederOverview/saga";

import { show, hide } from "../helpers/helper";

/** **********************************************
 * **********************************************
 * ASSIGN
 */
import {
  watchFetchFileList,
  watchFetchTestType,
  watchFetchMaterialType,
  watchFetchTestProtocol,
  watchFetchMaterialState,
  watchFetchContainerType,
  watchFetchAssignData,
  watchFetchAssignFilterData,
  watchFetchAssignClearData,
  watchFetchBreeding,
  watchFetchImportSource,
  watchpostSaveNrOfSamples,
  watchDeletePost,
  watchFetchS2S,
  watchSaveS2Smarker,
  watchAddToS2S,
  watchS2SFillRate,
  watchUploadS2S,
  watchProjectList,
  postS2SmanageMarker,
  fetchCNT,
  fetchSaveCNTMarker,
  fetchCNTDataWithMarkers,
  postCNTMnagMarkers,
  getCNTExport,
  getApprovedSlots,
  fetchRDTMaterialWithTest,
  fetchSaveRDTAssignTests,
  fetchGetRDTMaterialState,
  postRdtRequestSampleTest,
  postRdtUpdateRequestSampleTest,
  postRDTprint,
  fetchGetMasterGetSites,
  fetchUserCrops,
  watchfetchConfigurationList,
  postLeafDiskRequestSampleTest,
  leafDiskPrintLabel,
  seedHealthPrintLabel
} from "../containers/Home/saga";

import {
  watchGetDetermination,
  watchGetTrait,
  watchGetRelation,
  watchGetCrop,
  watchPostRelation
} from "../containers/Trait/sagaTrait";
import {
  watchGetResult,
  watchPostResult,
  watchGetTraitValues,
  watchGetCheckValidation
} from "../containers/TraitResult/saga";

import {
  watchMailConfigFetch,
  watchMailConfigAdd,
  watchMailConfigDelete
} from "../containers/Mail/mailSaga";

import {
  watchGetPlatPlan,
  watchPostPlatPlanExport
} from "../containers/PlatPlan/saga";
import {
  watchGetRDToverview,
  watchRDToverviewExcel
} from "../containers/RDTOverview/saga";

import {
  watchGetLDOverview,
  watchLDOverviewExcel
} from "../containers/LDOverview/saga";

import {
  watchGetSHOverview,
  watchSHOverviewExcel
} from "../containers/SHOverview/saga";

import {
  watchGetSHResult,
  watchPostSHResult
} from "../containers/SHResult/saga";

import {
  watchPostProtocolList,
  watchGetProtocol,
  watchPostSaveProtocol
} from "../containers/LabProtocol/saga";

import {
  ctMaintainProcessFetch,
  ctMaintainProcessPost,
  ctLabLocationsFetch,
  ctLabLocationsPost,
  ctStartMaterialsFetch,
  ctStartMaterialsPost,
  ctTypeFetch,
  ctTypePost
} from "../containers/CTMaintain/CTMaintainSaga";

import {
  watchGetRDTResult,
  watchPostRDTResult,
  watchGetMappingColumns,
  watchGetMaterialStatus
} from "../containers/RdtResult/saga";

// UPLOAD FILE
function uploadFileApi(action) {
  const formData = new FormData();
  formData.append("file", action.file);
  formData.append("pageNumber", 1);
  formData.append("pageSize", action.pageSize);
  formData.append("testTypeID", action.testTypeID);
  formData.append("plannedDate", action.date);
  formData.append("expectedDate", action.expected);
  formData.append("materialTypeID", action.materialTypeID);
  formData.append("materialStateID", action.materialStateID);
  formData.append("containerTypeID", action.containerTypeID);
  formData.append("isolated", action.isolated);
  formData.append("source", action.source);
  formData.append("excludeControlPosition", action.excludeControlPosition);

  if (action.testTypeID === 9)
    formData.append("testProtocolID", action.testProtocolID);

  if (action.source === "External") {
    formData.append("cropCode", action.cropCode);
    formData.append("brStationCode", action.brStationCode);
    formData.append("btr", action.btr);
    formData.append("researcherName", action.researcherName);
  }

  /**
   * Source :: upload api is differetn
   * Breezys / External
   */
  const url =
    action.source === "Breezys"
      ? urlConfig.postFile
      : urlConfig.postExternalFile;
  return axios({
    method: "post",
    url,

    headers: {
      "content-type": "multipart/form-data"
    },
    data: formData
  });
}
function* uploadFile(action) {
  try {
    const result = yield call(uploadFileApi, action);
    const { data } = result;
    const { success, dataResult, total } = data;
    if (success) {
      // clearing data, col and marker
      yield put({ type: "RESET_ASSIGN" });

      yield put({ type: "DATA_BULK_ADD", data: dataResult.data });
      yield put({ type: "COLUMN_BULK_ADD", data: dataResult.columns });
      yield put({ type: "TOTAL_RECORD", total });
      // changeing page to one
      yield put({ type: "PAGE_RECORD", pageNumber: 1 });
      // REFETCH FILE LIST
      const { breedingStationCode: selected, cropCode } = data.file;
      // selction of breeding station
      yield put({ type: "BREEDING_STATION_SELECTED", selected });
      // selection of crop
      yield put({ type: "ADD_SELECTED_CROP", crop: cropCode });

      yield put({
        type: "FILELIST_FETCH",
        breeding: selected,
        crop: cropCode,
        testTypeMenu: action.testTypeMenu
      });
      yield put({ type: "FILTER_CLEAR" });
      yield put({ type: "FILTER_PLATE_CLEAR" });

      // selecting in the list
      data;
      const tobj = {
        testTypeID: data.file.testTypeID,
        cropCode: data.file.cropCode,
        fileID: data.file.fileID,
        fileTitle: data.file.fileTitle,
        testID: data.file.testID,
        importDateTime: data.file.importDateTime,
        plannedDate: data.file.plannedDate,
        userID: data.file.userID,
        remark: data.file.remark || "",
        remarkRequired: data.file.remarkRequired,
        statusCode: data.file.statusCode,
        slotID: null,
        source: action.source || "",
        excludeControlPosition: data.file.excludeControlPosition || false
      };
      yield put({ type: "FILELIST_ADD_NEW", file: tobj });

      // marker fetch :: works good
      if (action.determinationRequired) {
        yield put({
          type: "FETCH_MARKERLIST",
          testID: data.file.testID,
          cropCode: data.file.cropCode,
          testTypeID: action.testTypeID,
          source: action.source
        });
      }
      // setting rootTestID
      yield put({
        type: "ROOT_SET_ALL",
        testID: data.file.testID,
        testTypeID: action.testTypeID,
        remark: data.file.remark || "",
        statusCode: data.file.statusCode,
        remarkRequired: data.file.remarkRequired,
        slotID: null
      });

      yield put({
        type: "FETCH_TESTLOOKUP",
        breedingStationCode: selected,
        cropCode,
        testTypeMenu: action.testTypeMenu
      });
      // setting Filling page to 1 if new file selected
      // home
      yield put({ type: "PAGE_RECORD", pageNumber: 1 });
      // plate
      yield put({ type: "PAGE_PLATE_RECORD", pageNumber: 1 });
      // update test file attributes
      yield put({ type: "SELECT_MATERIAL_TYPE", id: action.materialTypeID });
      yield put({ type: "SELECT_TEST_PROTOCOL", id: action.testProtocolID });
      yield put({ type: "SELECT_MATERIAL_STATE", id: action.materialStateID });
      yield put({ type: "SELECT_CONTAINER_TYPE", id: action.containerTypeID });
      yield put({
        type: "CHANGE_ISOLATION_STATUS",
        isolationStatus: action.isolated
      });
      yield put({ type: "TESTTYPE_SELECTED", id: action.testTypeID });
      yield put({ type: "ROOT_TESTTYPEID", testTypeID: action.testTypeID });
      yield put({ type: "CHANGE_PLANNED_DATE", plannedDate: action.date });
    } else {
      const obj = {};
      obj.message = data.errors;
      yield put(notificationMsg(obj));
    }
  } catch (e) {
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}
function* watchUploadFile() {
  yield takeLatest("UPLOAD_ACTION", uploadFile);
}

/**
 * NOT user check and remove
 * watchExternalMarker
 * externalMarker
 * externalMarkerApi
 * @param {} action
 */
function externalMakerApi(action) {
  console.log(action);
  return true;
}
function* externalMaker(action) {
  try {
    const result = yield call(externalMakerApi, action);
    console.log(result);
  } catch (e) {
    console.log(e);
  }
}
export function* watchExternalMarker() {
  yield takeLatest("EXTERNAL_MARKERLIST", externalMaker);
}

// FETCH MARKER LIST
function fetchMarkerListApi(directfromStateSource, action) {
  const checkSource = directfromStateSource || action.source;
  if (checkSource === "External") {
    return axios({
      method: "get",
      url: urlConfig.getExternalDeterminations,

      params: {
        cropCode: action.cropCode,
        testTypeID: action.testTypeID
      }
    });
  }
  return axios({
    method: "get",
    url: urlConfig.getMarkers,

    params: {
      cropCode: action.cropCode,
      testTypeID: action.testTypeID,
      testID: action.testID
    }
  });
}
function* fetchMarkerList(action) {
  /**
   * Need to get source from state as in file edit fetaure
   * source in not passed and it making difficult to select
   * which url/api to use
   */
  const getSource = state => state.assignMarker.file.selected.source;
  const directfromStateSource = yield select(getSource);
  try {
    const result = yield call(
      fetchMarkerListApi,
      directfromStateSource,
      action
    );
    const markers = result.data;
    yield put({
      type: "MARKER_BULK_ADD",
      data: markers.map(d => ({ ...d, selected: false }))
    });
  } catch (e) {
    e;
  }
}
function* watchFetchMarkerList() {
  yield takeLatest("FETCH_MARKERLIST", fetchMarkerList);
}

// NEW PAGE
function* fetchNewPageData(action) {
  try {
    yield put(show("fetchNewPageData"));
    const { testTypeID, pageSize } = action;

    const result = yield call(fetchAssignFilterDataApi, action);
    const { data } = result;
    const { success, dataResult, total } = data;
    if (success) {
      yield put({ type: "DATA_BULK_ADD", data: dataResult.data });
      yield put({ type: "COLUMN_BULK_ADD", data: dataResult.columns });
      yield put({ type: "TOTAL_RECORD", total });
      yield put({ type: "SIZE_RECORD", pageSize});
      yield put({ type: "PAGE_RECORD", pageNumber: action.pageNumber });

      //Leafdisk & Seedhealth
      if (testTypeID === 9 || testTypeID === 10) {
        const leafDiskMaterialMap = {};
        //for #plants
        const refresh = yield select(
          state => !state.assignMarker.materials.refresh
        );

        const existingData = yield select(
          state => state.assignMarker.materials.leafDiskMaterialMap
        );

        data.dataResult.data.forEach(row => {
          const key = `${row.materialID}-#plants`;

          if (Object.keys(existingData).includes(key))
            leafDiskMaterialMap[key] = existingData[key];
          else
            leafDiskMaterialMap[key] = {
              '#plants': row['#plants'] || "",
              changed: false,
              newState: row['#plants'] || ""
            };
        });

        yield put({ type: "ADD_LDMATERIAL_MAP", leafDiskMaterialMap, refresh });
      }
    }
    yield put(hide("fetchNewPageData"));
  } catch (e) {
    yield put(hide("fetchNewPageData"));
    e;
  }
}
function* watchFetchNewPageData() {
  yield takeLatest("NEW_PAGE", fetchNewPageData);
}
/** **********************************************
 * **********************************************
 * FILLING
 */
// TESTLOOKUP
function fetchTestLookupApi(breedingStationCode, cropCode, testTypeMenu) {
  return axios({
    method: "get",
    url: urlConfig.getTestsLookup,
    params: {
      breedingStationCode,
      cropCode,
      testTypeMenu
    }
  });
}

function* fetchTestLookup(action) {
  try {
    const { breedingStationCode, cropCode, testTypeMenu } = action;
    const result = yield call(
      fetchTestLookupApi,
      breedingStationCode,
      cropCode,
      testTypeMenu
    );

    yield put({
      type: "TESTSLOOKUP_ADD",
      data: result.data
    });

    const rootTest = yield select(state => state.rootTestID);

    if (rootTest.testID !== null) {
      const v = result.data.filter(f => f.testID === rootTest.testID)[0];
      if (v) {
        yield put({
          type: "ROOT_SET_ALL",
          testID: v.testID,
          testTypeID: v.testTypeID,
          statusCode: v.statusCode,
          statusName: v.statusName,
          remark: v.remark,
          remarkRequired: v.remarkRequired,
          slotID: v.slotID,
          platePlanName: v.platePlanName,
          source: v.source,
          importLevel: v.importLevel
        });
      }
      yield put({
        type: "TESTSLOOKUP_SELECTED",
        ...v
      });
    }
  } catch (e) {
    yield put(noInternet);
  }
}

const cancelable = (saga, cancelAction) =>
  function* cancelCancelable(...args) {
    yield race([call(saga, ...args), take(cancelAction)]);
  };

function* watchFetchTestLookup() {
  yield takeLatest(
    "FETCH_TESTLOOKUP",
    cancelable(fetchTestLookup, "CANCEL_FETCH_TESTLOOKUP")
  );
}

// PLANT
function fetchPlantApi(action) {
  return axios({
    method: "get",
    url: urlConfig.getPlant,

    params: {
      testID: action.testID,
      query: action.value
    }
  });
}
function* fetchPlant(action) {
  try {
    const result = yield call(fetchPlantApi, action);
    const { data } = result;
    yield put({
      type: "PLANT_BULK_ADD",
      data
    });
  } catch (e) {
    yield put(noInternet);
  }
}
function* watchFetchPlant() {
  yield takeLatest("FETCH_PLANT", fetchPlant);
}

// PLATE AFTER FILTER
function* fetchPlateFilterData(action) {
  try {
    const result = yield call(fetchPlateDataApi, action);
    const { data } = result;
    yield put({
      type: "FILTER_PLATE_ADD_BLUK",
      filter: action.filter
    });
    yield put({
      type: "DATA_FILLING_BULK_ADD",
      data: data.data.data
    });
    yield put({
      type: "COLUMN_FILLING_BULK_ADD",
      data: data.data.columns
    });
    yield put({
      type: "TOTAL_PLATE_RECORD",
      total: data.total
    });
    yield put({
      type: "FILTERED_TOTAL_PLATE_RECORD",
      grandTotal: data.totalCount
    });

    yield put({
      type: "PAGE_PLATE_RECORD",
      pageNumber: action.pageNumber
    });
  } catch (e) {
    yield put(noInternet);
  }
}
function* watchFetchPlateFilterData() {
  yield takeLatest("FETCH_PLATE_FILTER_DATA", fetchPlateFilterData);
}
// PLATE FILTER CLEAR
function* actionPlateFilterClear(action) {
  try {
    const result = yield call(fetchPlateDataApi, action);
    const { data } = result;
    yield put({
      type: "DATA_FILLING_BULK_ADD",
      data: data.data.data
    });
    yield put({
      type: "TOTAL_PLATE_RECORD",
      total: data.total
    });
    yield put({
      type: "PAGE_PLATE_RECORD",
      pageNumber: action.pageNumber
    });
    yield put({
      type: "FILTER_PLATE_CLEAR"
    });
  } catch (e) {
    // yield put({ type: 'LOADER_HIDE' });
  }
}
function* watchActionPlateFilterClear() {
  yield takeLatest("FETCH_CLEAR_PLATE_FILTER_DATA", actionPlateFilterClear);
}
// ASSIGN FIX POSITION
function assignFixPositionApi(action) {
  return axios({
    method: "post",
    url: urlConfig.postAssignFixedPosition,

    data: {
      testID: action.testID,
      wellPosition: action.wellPosition,
      materialID: action.materialID
    }
  });
}
function* actionAssignFixPosition(action) {
  try {
    const result = yield call(assignFixPositionApi, action);
    const { data } = result;

    if (data) {
      yield put(notificationSuccessTimer("Fixed position assign success."));
      yield put({
        type: "WELL_REMOVE",
        position: action.wellPosition
      });
      yield put({
        type: "TESTSLOOKUP_SET_FIXEDPOSITION_CHANGE",
        testID: action.testID
      });
      // TODO :: need testign
      const pageSize = yield select(state => state.plateFilling.total.pageSize);
      const result2 = yield call(fetchPlateDataApi, {
        testID: action.testID,
        filter: [],
        pageNumber: 1,
        pageSize: pageSize || 200
      });
      const data2 = result2.data;
      yield put({
        type: "DATA_FILLING_BULK_ADD",
        data: data2.data.data
      });
      yield put({ type: "SIZE_PLATE_RECORD", pageSize: pageSize || 200 });
      yield put({
        type: "PAGE_PLATE_RECORD",
        pageNumber: 1
      });
      yield put({ type: "REQUEST_TOTAL_MARKER", testID: action.testID });
    } else {
      yield put(noInternet);
    }
  } catch (e) {
    if (e.response.data) {
      const error = e.response.data;
      yield put({
        type: "NOTIFICATION_SHOW",
        status: true,
        message: error.message,
        messageType: error.errorType,
        notificationType: 0,
        code: error.code
      });
    }
  }
}
function* watchActionAssignFixPosition() {
  yield takeLatest("ASSIGN_FIX_POSITION", actionAssignFixPosition);
}
// NEW PAGE
function* fetchNewPlatePageData(action) {
  try {
    yield put(show("fetchNewPageData"));
    const result = yield call(fetchPlateDataApi, action);
    const { data } = result.data;
    yield put({
      type: "DATA_FILLING_BULK_ADD",
      data: data.data
    });
    yield put({
      type: "COLUMN_FILLING_BULK_ADD",
      data: data.columns
    });
    yield put({
      type: "TOTAL_PLATE_RECORD",
      total: result.data.total
    });
    yield put({
      type: "PAGE_PLATE_RECORD",
      pageNumber: action.pageNumber
    });

    yield put(hide("fetchNewPageData"));
  } catch (e) {
    yield put(hide("fetchNewPageData"));
  }
}
function* watchFetchNewPlatePageData() {
  yield takeLatest("NEW_PLATE_PAGE", fetchNewPlatePageData);
}

// GET PUNCH LIST
function fetchPunchListApi(action) {
  return axios({
    method: "get",
    url: urlConfig.getPunchList,

    params: {
      testID: action.testID
    }
  });
}
function* fetchPunchList(action) {
  try {
    // ADD_PUNCHLIST
    const result = yield call(fetchPunchListApi, action);
    yield put({
      type: "ADD_PUNCHLIST",
      data: result.data
    });
  } catch (e) {
    e;
  }
}
function* watchFetchPunchList() {
  yield takeLatest("FETCH_PUNCHLIST", fetchPunchList);
}

// GET Leaf Disk PUNCH LIST
function fetchLDPunchListApi(action) {
  return axios({
    method: "get",
    url: urlConfig.getLDPunchList,

    params: {
      testID: action.testID
    }
  });
}
function* fetchLDPunchList(action) {
  try {
    const result = yield call(fetchLDPunchListApi, action);
    yield put({
      type: "LD_ADD_PUNCHLIST",
      data: result.data
    });
  } catch (e) {
    console.error(e);
  }
}

function* watchLDFetchPunchList() {
  yield takeLatest("LD_FETCH_PUNCHLIST", fetchLDPunchList);
}

// POST PLATE LABEL
function requestPlateLabelApi(action) {
  return axios({
    method: "post",
    url: urlConfig.postPlateLabel,

    data: {
      testID: action.testID
    }
  });
}
function* requestPlateLabel(action) {
  try {
    const result = yield call(requestPlateLabelApi, action);
    const { data } = result;
    // result acc :: success, error, printerName
    if (data.success) {
      // TODO :: check this message after service circle works.
      yield put(notificationSuccessTimer("Plate label queued for printing."));
      // data.printerName
    } else {
      const obj = {};
      obj.message = data.error;
      yield put(notificationMsg(obj));
    }
  } catch (e) {
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}
function* watchRequestPlateLabel() {
  yield takeLatest("PLATE_LABEL_REQUEST", requestPlateLabel);
}
// REMARK
function postRemarkApi(action) {
  return axios({
    method: "put",
    url: urlConfig.putTestSaveRemark,

    data: {
      testID: action.testID,
      remark: action.remark
    }
  });
}
function* postRemark(action) {
  try {
    const result = yield call(postRemarkApi, action);
    if (result.data) {
      yield put({
        type: "ROOT_REMARK",
        remark: action.remark
      });
      yield put({
        type: "FILELIST_SET_REMARK",
        testID: action.testID,
        remark: action.remark
      });
      yield put({
        type: "TESTSLOOKUP_SET_REMARK",
        testID: action.testID,
        remark: action.remark
      });
      yield put(notificationSuccessTimer("Remark successfully saved."));
    }
  } catch (e) {
    yield put(noInternet);
  }
}
function* watchPostRemark() {
  yield takeLatest("ROOT_SET_REMARK", postRemark);
}
// COMPLETE REQUEST && REMARK
function confirmRequestApi(action) {
  return axios({
    method: "put",
    url: urlConfig.putCompleteTestRequest,

    data: {
      testId: action.testId
    }
  });
}
function* confirmRequest(action) {
  try {
    const result = yield call(confirmRequestApi, action);
    if (action.testId === result.data.testID) {
      yield put({
        type: "ROOT_STATUS",
        statusCode: result.data.statusCode,
        testID: result.data.testID
      });
      yield put(notificationSuccessTimer("Confirm request successfully."));
    }
  } catch (e) {
    if (e.response.data) {
      const error = e.response.data;
      yield put({
        type: "NOTIFICATION_SHOW",
        status: true,
        message: error.message,
        messageType: error.errorType,
        notificationType: 0,
        code: error.code
      });
    } else {
      yield put(noInternet);
    }
  }
}
function* watchConfirmRequest() {
  yield takeLatest("TESTSLOOKUP_CONFIRM_REQUEST", confirmRequest);
}

// Plate Reserve Call
function toLIMSApi(action) {
  return axios({
    method: "post",
    url: urlConfig.postPlateInLims,

    data: {
      testID: action.testID
    }
  });
}
function* toLIMS(action) {
  try {
    const result = yield call(toLIMSApi, action);
    yield put({
      type: "ROOT_STATUS",
      statusCode: result.data.statusCode,
      testID: result.data.testID
    });
    yield put(notificationSuccessTimer("Request sent to LIMS successfully."));
  } catch (e) {
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}
function* watchToLIMS() {
  yield takeLatest("REQUEST_TO_LIMS", toLIMS);
}

// Lab Location
function fetchLabLocationApi() {
  return axios({
    method: "get",
    url: urlConfig.getMasterGetSites
  });
}

function* fetchLabLocation() {
  try {
    yield put(show("fetchLabLocation"));
    const result = yield call(fetchLabLocationApi);
    const { data } = result;
    yield put({
      type: "LAB_LOCATION_ADD",
      data
    });
    yield put(hide("fetchLabLocation"));
  } catch (e) {
    yield put(hide("fetchLabLocation"));
  }
}

/** **********************************************
 *  *********************************************
 * FINAL CALL
 */
export default function* rootSaga() {
  yield all([
    watchPostProtocolList(),
    watchGetProtocol(),
    watchPostSaveProtocol(),

    watchFetchGetExternalTests(),
    watchExportTest(),

    watchGetSlotList(),
    watchPostLinkSlotTest(),

    watchFetchFileList(),
    watchUploadFile(),
    watchFetchMaterialType(),
    watchFetchTestProtocol(),
    watchFetchMaterialState(),
    watchFetchContainerType(),
    watchFetchAssignData(),
    watchFetchTestType(),
    watchFetchMarkerList(),
    watchAssignMarker(),
    watchAddToThreeGB(),
    watchFetchThreeGB(),
    watchSave3GBmarker(),
    watchAddToS2S(),
    watchFetchS2S(),
    watchSaveS2Smarker(),
    watchS2SFillRate(),
    watchUploadS2S(),
    watchProjectList(),
    watchfetchConfigurationList(),
    yield takeLatest(
      "POST_S2S_ASSIGN_MARKER_WITH_SELECTION_ROW",
      postS2SmanageMarker
    ),

    watchFetchAssignFilterData(),
    watchFetchAssignClearData(),
    watchFetchBreeding(),
    watchFetchImportSource(),
    watchpostSaveNrOfSamples(),
    watchDeletePost(),

    watchFetchNewPageData(),
    watchFetchTestLookup(),
    watchFetchWell(),
    watchFetchPlant(),
    watchFetchPlateData(),
    watchFetchNewPlatePageData(),
    watchActionAssignFixPosition(),
    watchActionSaveDB(),
    watchFetchPlateFilterData(),
    watchActionPlateFilterClear(),
    watchFetchPunchList(),
    watchLDFetchPunchList(),
    watchRequestPlateLabel(),
    watchReservePlate(),
    watchUndoFixedPosition(), // undoFix
    watchToLIMS(),
    watchPostRemark(),
    watchConfirmRequest(),
    watchDeleteRow(),
    watchUndoDead(),
    watchDeleteReplicate(),
    watchFetchWellType(),
    watchFetchStatusList(),
    watchFetchMaterials(),
    watchFetchMaterialsWithDeterminationsForExternalTest(),
    watchUpdateTestAttributesDispatch(),
    watchFetchFilteredMaterials(),
    watchCreateReplicaDispatch(),
    watchDeleteDeadMaterialsDispatch(),
    watchSaveMaterialMarker(),
    watchExternalMarker(),
    watchPlateFillingExcel(),
    watchPlateFillingTotalMarker(),

    watchBreeder(),
    watchCropChange(),
    watchBreederReserve(),
    watchPeriod(),
    watchPlantsTests(),
    watchSlotDelete(),
    watchSlotEdit(),

    watchLeafDiskCapacityPlanning(),
    watchLeafDiskCapacityPlanningCropChange(),
    watchLeafDiskCapacityPlanningReserve(),
    watchLeafDiskCapacityPlanningPeriod(),
    watchLeafDiskCapacityPlanningAvailableSample(),
    watchLeafDiskCapacityPlanningSlotDelete(),
    watchLeafDiskCapacityPlanningSlotEdit(),
    watchLeafDiskFetchSlot(),
    watchExportCapacityPlanningLeafDisk(),
    watchsaveConfigName(),

    watchPlanningCapacity(),
    watchPlanningUpdate(),
    watchLabOverview(),
    watchLabOverviewExcel(),
    watchLabSlotEdit(),

    watchLDLabOverview(),
    watchLDLabOverviewExcel(),
    watchLDLabSlotEdit(),

    watchLDplanningCapacity(),
    watchLDplanningUpdate(),

    watchGetApprovalList(),
    watchGetPlanPeriods(),
    watchSlotApproval(),
    watchSlotDenial(),
    watchUpdateSlotPeriod(),

    watchGetLDApprovalList(),
    watchGetLDPlanPeriods(),
    watchLDSlotApproval(),
    watchLDSlotDenial(),
    watchUpdateLDSlotPeriod(),

    watchGetLDOverview(),
    watchLDOverviewExcel(),

    watchGetSHOverview(),
    watchSHOverviewExcel(),
    watchGetSHResult(),
    watchPostSHResult(),

    yield takeLatest("PHENOME_LOGIN", phenomeLogin),
    yield takeLatest("GET_RESEARCH_GROUPS", getResearchGroups),
    yield takeLatest("GET_FOLDERS", getFolders),
    yield takeLatest("IMPORT_PHENOME", importPhenome),
    yield takeLatest("THREEGB_PROJECTLIST_FETCH", getBGAvailableProjects),
    yield takeLatest("THREEGB_SEND_COCKPIT", sendToThreeGBCockpit),
    yield takeLatest("FETCH_S2S_CAPACITY", getS2SCapacity),

    watchGetDetermination(),
    watchGetTrait(),
    watchGetRelation(),
    watchGetCrop(),
    watchPostRelation(),

    watchGetResult(),
    watchPostResult(),
    watchGetTraitValues(),
    watchGetCheckValidation(),

    watchFetchSlot(),

    watchMailConfigFetch(),
    watchMailConfigAdd(),
    watchMailConfigDelete(),

    yield takeLatest("CT_PROCESS_FETCH", ctMaintainProcessFetch),
    yield takeLatest("CT_PROCESS_POST", ctMaintainProcessPost),
    yield takeLatest("CT_LABLOCATIONS_FETCH", ctLabLocationsFetch),
    yield takeLatest("CT_LABLOCATIONS_POST", ctLabLocationsPost),
    yield takeLatest("CT_STARTMATERIAL_FETCH", ctStartMaterialsFetch),
    yield takeLatest("CT_STARTMATERIAL_POST", ctStartMaterialsPost),
    yield takeLatest("CT_TYPE_FETCH", ctTypeFetch),
    yield takeLatest("CT_TYPE_POST", ctTypePost),

    yield takeLatest("FETCH_CNT", fetchCNT),
    yield takeLatest("SAVE_CNT_MATERIAL_MARKER", fetchSaveCNTMarker),
    yield takeLatest("FETCH_CNT_DATA_WITH_MARKERS", fetchCNTDataWithMarkers),
    yield takeLatest("POST_CNT_MANAGE_MARKERS", postCNTMnagMarkers),
    yield takeLatest("GET_CNT_EXPORT_EXCEL", getCNTExport),
    yield takeLatest("GET_APPROVED_SLOTS", getApprovedSlots),

    yield takeLatest("FETCH_RDT_MATERIAL_WITH_TESTS", fetchRDTMaterialWithTest),
    yield takeLatest("SAVE_RDT_MATERIAL_MARKER", fetchSaveRDTAssignTests),
    yield takeLatest("FETCH_RDT_MATERIAL_STATE", fetchGetRDTMaterialState),
    yield takeLatest("POST_RDT_REQ_SAMPLE", postRdtRequestSampleTest),
    yield takeLatest("UPDATE_RDT_REQ_SAMPLE", postRdtUpdateRequestSampleTest),
    yield takeLatest("POST_RDT_PRINT", postRDTprint),

    yield takeLatest("FETCH_GETSITES", fetchGetMasterGetSites),
    yield takeLatest("FETCH_USER_CROPS", fetchUserCrops),
    yield takeLatest("FETCH_PHENOM_TOKEN", fetchPhenomToken),

    yield takeLatest("LAB_LOCATION_FETCH", fetchLabLocation),
    yield takeLatest("POST_LEAF_DISK_REQ_SAMPLE", postLeafDiskRequestSampleTest),
    yield takeLatest("LEAF_DISK_PRINT_LABEL", leafDiskPrintLabel),

    yield takeLatest("SEED_HEALTH_PRINT_LABEL", seedHealthPrintLabel),

    watchGetPlatPlan(),
    watchPostPlatPlanExport(),

    watchGetRDToverview(),
    watchRDToverviewExcel(),

    watchGetRDTResult(),
    watchPostRDTResult(),
    watchGetMappingColumns(),
    watchGetMaterialStatus(),
    watchExportCapacityPlanning(),
    watchFetchLeafDiskSampleData(),
    watchSaveSample(),
    watchFetchSamples(),
    watchAddMaterialsToSample(),
    watchFetchMaterialDeterminations(),
    watchfetchLeafDiskDeterminations(),
    watchAssignLDDeterminations(),
    watchSaveLDDeterminationsChanged(),
    watchUpdateTestMaterial(),
    watchDeleteSample(),

    watchFetchSeedHealthSampleData(),
    watchFetchSHMaterialDeterminations(),
    watchfetchSeedHealthDeterminations(),
    watchSaveSHDeterminationsChanged(),
    watchAssignSHDeterminations(),
    watchSHDeleteSample(),
    watchExportToExcelSH(),
    watchSendToABSSH()
  ]);
}
