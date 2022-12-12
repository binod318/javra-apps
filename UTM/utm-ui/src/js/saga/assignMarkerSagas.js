import { call, put, takeLatest } from "redux-saga/effects";
import axios from "axios";
import urlConfig from "../urlConfig";
import {
  notificationMsg,
  notificationGeneric,
  notificationSuccessTimer
} from "./notificationSagas";
import { show, hide } from "../helpers/helper";

function fetchMaterialsApi(action) {
  const data = { ...action };
  delete data.type;
  return axios({
    method: "post",
    url: urlConfig.getMaterials,

    data
  });
}
function* fetchMaterials(action) {
  try {
    yield put(show("fetchMaterials"));
    const result = yield call(fetchMaterialsApi, action);
    if (result.data) {
      const markerMaterialMap = {};
      const samples = [];

      const determinations =
        result.data.data.columns &&
        result.data.data.columns.filter(
          col =>
            col.traitID && col.traitID.substring(0, 2).toLowerCase() === "d_"
        );
      const determinationColumns = determinations.map(col =>
        col.traitID.toLowerCase()
      );
      result.data.data.data.forEach(row => {
        // state NumberOfSamples
        samples.push({
          materialID: row.materialID,
          nrOfSample: row.nrOfSamples,
          changed: false
        });
        determinationColumns.forEach(col => {
          markerMaterialMap[`${row.materialID}-${col}`] = {
            originalState: row[col],
            changed: false,
            newState: row[col]
          };
        });
      });

      // number of sample
      yield put({ type: "SAMPLE_NUMBER", samples });
      yield put({
        type: "FETCH_MATERIALS_SUCCEEDED",
        materials: result.data,
        markerMaterialMap
      });
    }

    yield put(hide("fetchMaterials"));
  } catch (e) {
    yield put(hide("fetchMaterials"));
    yield put({ type: "FETCH_MATERIALS_FAILED" });
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
export function* watchFetchMaterials() {
  yield takeLatest("FETCH_MATERIALS", fetchMaterials);
}

function fetchMaterialsWithDeterminationsForExternalTestApi(action) {
  const data = { ...action };
  delete data.type;
  return axios({
    method: "post",
    url: urlConfig.getMaterialsWithDeterminationsForExternalTest,

    data
  });
}
function* fetchMaterialsWithDeterminationsForExternalTest(action) {
  try {
    const result = yield call(
      fetchMaterialsWithDeterminationsForExternalTestApi,
      action
    );
    if (result.data) {
      const markerMaterialMap = {};
      const determinations =
        result.data.data.columns &&
        result.data.data.columns.filter(
          col =>
            col.traitID && col.traitID.substring(0, 2).toLowerCase() === "d_"
        );

      const determinationColumns = determinations.map(col =>
        col.traitID.toLowerCase()
      );
      result.data.data.data.forEach(row => {
        determinationColumns.forEach(col => {
          markerMaterialMap[`${row.materialID}-${col}`] = {
            originalState: row[col],
            changed: false,
            newState: row[col]
          };
        });
      });
      yield put({
        type: "FETCH_MATERIALS_SUCCEEDED",
        materials: result.data,
        markerMaterialMap
      });
    }
  } catch (e) {
    yield put({ type: "FETCH_MATERIALS_FAILED" });
  }
}
export function* watchFetchMaterialsWithDeterminationsForExternalTest() {
  yield takeLatest(
    "FETCH_MATERIAL_EXTERNAL",
    fetchMaterialsWithDeterminationsForExternalTest
  );
}

export function* watchFetchFilteredMaterials() {
  yield takeLatest("FETCH_FILTERED_MATERIAL", fetchMaterials);
}

function updateTestAttributesApi(attributes) {
  return axios({
    method: "post",
    url: urlConfig.updateTestAttributes,

    data: attributes
  });
}
function* updateTestAttributes({ attributes }) {
  try {
    yield put(show("updateTestAttributes"));
    const response = yield call(updateTestAttributesApi, attributes);

    if (response.status === 200) {
      yield put({
        type: "SELECT_MATERIAL_TYPE",
        id: attributes.materialTypeID
      });
      yield put({
        type: "SELECT_TEST_PROTOCOL",
        id: attributes.testProtocolID
      });
      yield put({
        type: "SELECT_MATERIAL_STATE",
        id: attributes.materialStateID
      });
      yield put({
        type: "SELECT_CONTAINER_TYPE",
        id: attributes.containerTypeID
      });
      yield put({
        type: "CHANGE_ISOLATION_STATUS",
        isolationStatus: attributes.isolated
      });
      yield put({
        type: "CHANGE_CUMULATE_STATUS",
        cumulate: attributes.cumulate
      });
      yield put({ type: "TESTTYPE_SELECTED", id: attributes.testTypeID });
      yield put({ type: "ROOT_TESTTYPEID", testTypeID: attributes.testTypeID });
      yield put({
        type: "CHANGE_PLANNED_DATE",
        plannedDate: attributes.plannedDate
      });
      yield put({
        type: "CHANGE_EXPECTED_DATE",
        expectedDate: attributes.expectedDate
      });
      yield put({
        type: "FILELIST_FETCH",
        breeding: attributes.breeding,
        crop: attributes.cropCode,
        empty: false
      });
      if (attributes.determinationRequired) {
        yield put({
          type: "FETCH_MARKERLIST",
          testID: attributes.testID,
          cropCode: attributes.cropCode,
          testTypeID: attributes.testTypeID
        });
      } else {
        yield put({ type: "RESET_MARKER_LIST" });
      }

      yield put(
        notificationSuccessTimer("Test Attributes updated successfully.")
      ); // eslint-disable-line
    } else {
      yield put({ type: "UPDATE_ATTRIBUTES_FAILURE" });
      yield put(
        notificationMsg({
          message: "Test Attributes could not be updated now. Try Again Later"
        })
      );
    }
    yield put(hide("updateTestAttributes"));
  } catch (e) {
    yield put(hide("updateTestAttributes"));
    yield put({ type: "UPDATE_ATTRIBUTES_FAILURE" });
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
export function* watchUpdateTestAttributesDispatch() {
  yield takeLatest("UPDATE_TEST_ATTRIBUTES", updateTestAttributes);
}

function saveMaterialMarkerApi(action) {
  const data = { ...action.materialsMarkers };
  return axios({
    method: "post",
    url: urlConfig.saveDeterminations,

    data
  });
}
function* saveMaterialMarker(action) {
  try {
    const result = yield call(saveMaterialMarkerApi, action);

    if (result.data) {
      yield put({ type: "MATERIALS_MARKER_SAVE_SUCCEEDED" });
      yield put({ type: "MARKER_DISELECT" });
      yield put({
        type: "ROOT_STATUS",
        statusCode: result.data.statusCode
      });
      yield put(notificationSuccessTimer("Markers are successfully assigned."));
    }
  } catch (e) {
    yield put({ type: "FETCH_MATERIALS_FAILED" });
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
export function* watchSaveMaterialMarker() {
  yield takeLatest("SAVE_MATERIAL_MARKER", saveMaterialMarker);
}

function assignMarkerApi(action) {
  return axios({
    method: "post",
    url: urlConfig.postMarkers,

    data: {
      testID: action.testID,
      testTypeID: action.testTypeID,
      determinations: action.determinations,
      filter: action.filter
    }
  });
}
function* assignMarker(action) {
  try {
    const result = yield call(assignMarkerApi, action);
    if (result.data) {
      yield put({
        type: "ROOT_STATUS",
        statusCode: result.data.statusCode
      });
      yield put({ type: "MARKER_DISELECT" });
      yield put(notificationSuccessTimer("Markers are successfully assigned."));
    }
  } catch (e) {
    yield put(notificationGeneric());
  }
}
export function* watchAssignMarker() {
  yield takeLatest("ASSIGN_MARKERLIST", assignMarker);
}
// 3GB
function addToThreeGBApi(action) {
  return axios({
    method: "post",
    url: urlConfig.postAddToThreeGB,

    data: {
      testID: action.testID,
      filter: action.filter
    }
  });
}
function* addToThreeGB(action) {
  try {
    const result = yield call(addToThreeGBApi, action);
    if (result.data) {
      yield put(notificationSuccessTimer("Successfully changed."));
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
export function* watchAddToThreeGB() {
  yield takeLatest("ADD_TO_THREEGB", addToThreeGB);
}

function fatchThreeGBApi(action) {
  const data = { ...action };
  delete data.type;
  return axios({
    method: "post",
    url: urlConfig.postGetThreeGBmaterial,

    data
  });
}
function* fetchThreeGB(action) {
  try {
    yield put(show("fetchThreeGB"));

    const result = yield call(fatchThreeGBApi, action);
    if (result.data) {
      const markerMaterialMap = {};
      const samples = [];
      result.data.data.data.forEach(row => {
        // //////////////////////////
        // / ## HOT 3GB CHANGE
        // / ///////////////////////////
        // markerMaterialMap[`${row.materialKey}-d_To3GB`] = {
        // markerMaterialMap[`${row.materialKey}-d_Selected`] = {
        markerMaterialMap[`${row.materialID}-d_selected`] = {
          // originalState: row.d_To3GB ? 1 : 0,
          // newState: row.d_To3GB ? 1 : 0,
          originalState: row.d_Selected ? 1 : 0,
          newState: row.d_Selected ? 1 : 0,
          changed: false,
          mk: row.materialKey
        };
        samples.push({
          materialID: row.materialID,
          nrOfSample: row.nrOfSamples,
          changed: false
        });
      });
      // number of sample
      yield put({ type: "SAMPLE_NUMBER", samples });
      yield put({
        type: "FETCH_MATERIALS_SUCCEEDED",
        materials: result.data,
        markerMaterialMap
      });
    }
    yield put(hide("fetchThreeGB"));
  } catch (e) {
    yield put(hide("fetchThreeGB"));
    yield put({ type: "FETCH_MATERIALS_FAILED" });
  }
}
export function* watchFetchThreeGB() {
  yield takeLatest("FETCH_THREEGB", fetchThreeGB);
}

function save3GBMarkerApi(action) {
  return axios({
    method: "post",
    url: urlConfig.postAddToThreeGB,

    data: {
      testID: action.testID,
      materialSelected: action.materialWithMarker
    }
  });
}
export function* fetchSave3GBMarker(action) {
  try {
    const { materialsMarkers } = action;
    const { materialWithMarker } = materialsMarkers;
    if (
      materialsMarkers &&
      materialWithMarker &&
      materialWithMarker.length === 0
    ) {
      return null;
    }

    const result = yield call(save3GBMarkerApi, materialsMarkers);
    if (result.data) {
      yield put({
        type: "MATERIALS_MARKER_SAVE_SUCCEEDED"
      });
      yield put(notificationSuccessTimer("Successfully changed."));
    }
  } catch (e) {
    yield put({ type: "FETCH_MATERIALS_FAILED" });
  }
  return null;
}
export function* watchSave3GBmarker() {
  yield takeLatest("SAVE_3GB_MATERIAL_MARKER", fetchSave3GBMarker);
}

function fetchLeafDiskSampleDataApi(action) {
  const data = action.payload;
  return axios({
    method: "post",
    url: urlConfig.getLeafDiskSampleData,
    data
  });
}

function* fetchLeafDiskSampleData(action) {
  yield put(show("fetchLeafDiskSampleData"));

  try {
    const result = yield call(fetchLeafDiskSampleDataApi, action);
    yield put(hide("fetchLeafDiskSampleData"));
    if (result.data) {
      const { pageNumber, pageSize } = action.payload;
      yield put({
        type: "FETCH_LEAF_DISK_SAMPLE_DATA_SUCCEEDED",
        data: result.data,
        pageInfo: { pageSize, pageNumber }
      });
    }
  } catch (e) {
    yield put(hide("fetchLeafDiskSampleData"));
    yield put({ type: "FETCH_MATERIALS_FAILED" });
  }
}
export function* watchFetchLeafDiskSampleData() {
  yield takeLatest("FETCH_LEAF_DISK_SAMPLE_DATA", fetchLeafDiskSampleData);
}

function saveSampleApi(action) {
  const data = { ...action.payload };
  const testTypeID = data.testTypeID;
  delete data.testTypeID;

  return axios({
    method: "post",
    url: testTypeID === 9 ? urlConfig.saveleafDiskSample : urlConfig.saveSeedHealthSample,
    data
  });
}

function* saveSample(action) {
  yield put(show("saveSample"));

  try {
    yield call(saveSampleApi, action);
    yield put({ type: "SAVE_SAMPLE_SUCCEEDED" });
    yield put(hide("saveSample"));
  } catch (e) {
    yield put(hide("saveSample"));
  }
}
export function* watchSaveSample() {
  yield takeLatest("SAVE_SAMPLE", saveSample);
}

// Get samples
function fetchSamplesApi(action) {
  const { testID, testTypeID } = action;
  const url = testTypeID == 9 ? urlConfig.getLeafDiskSamples : urlConfig.getSeedHealthSamples;
  const fullUrl = `${url}?testID=${testID}`;
  return axios(fullUrl);
}

function* fetchSamples(action) {
  yield put(show("fetchSamples"));
  try {
    const result = yield call(fetchSamplesApi, action);
    // save sample list
    // const { pageNumber, pageSize } = action.payload;
    yield put({
      type: "FETCH_SAMPLES_SUCCEEDED",
      data: result.data
      // pageInfo: { pageNumber, pageSize }
    });
    yield put(hide("fetchSamples"));
  } catch (e) {
    yield put(hide("fetchSamples"));
  }
}
export function* watchFetchSamples() {
  yield takeLatest("FETCH_SAMPLES", fetchSamples);
}

// add materials to sample
function addMaterialsToSampleApi(action) {
  const data = { ...action.payload };
  const testTypeID = data.testTypeID;
  delete data.testTypeID;

  return axios({
    method: "post",
    url: testTypeID === 9 ? urlConfig.saveLeafDiskSampleMaterial : urlConfig.saveSeedHealthSampleMaterial,
    data
  });
}

function* addMaterialsToSample(action) {
  yield put(show("addMaterialsToSample"));

  try {
    yield call(addMaterialsToSampleApi, action);
    yield put(hide("addMaterialsToSample"));
  } catch (e) {
    yield put(hide("addMaterialsToSample"));
  }
}
export function* watchAddMaterialsToSample() {
  yield takeLatest("ADD_MATERIAL_TO_SAMPLE", addMaterialsToSample);
}

// add materials to sample
function fetchMaterialDeterminationsApi(action) {
  const data = { ...action.payload };
  return axios({
    method: "post",
    url: urlConfig.materialDeterminations,
    data
  });
}

// fetching Material determinations data
function* fetchMaterialDeterminations(action) {
  yield put(show("fetchMaterialDeterminations"));

  try {
    const result = yield call(fetchMaterialDeterminationsApi, action);
    if (result.data) {
      const { pageNumber, pageSize } = action.payload;
      yield put({
        type: "FETCH_MATERIAL_DETERMINATIONS_SUCCEEDED",
        data: result.data,
        pageInfo: {
          pageNumber,
          pageSize
        }
      });
    }
    yield put(hide("fetchMaterialDeterminations"));
  } catch (e) {
    yield put(hide("fetchMaterialDeterminations"));
  }
}

export function* watchFetchMaterialDeterminations() {
  yield takeLatest(
    "FETCH_MATERIAL_DETERMINATIONS",
    fetchMaterialDeterminations
  );
}

function updateTestMaterialApi(action) {
  const data = { ...action.payload };
  return axios({
    method: "post",
    url: urlConfig.saveLeafDiskMaterial,
    data
  });
}

function* updateTestMaterial(action) {
  yield put(show("updateTestMaterial"));

  try {
    yield call(updateTestMaterialApi, action);
    yield put({ type: "SAVE_TEST_MATERIAL_SUCCEEDED" });
    yield put(hide("updateTestMaterial"));
  } catch (e) {
    yield put(hide("updateTestMaterial"));
  }
}
export function* watchUpdateTestMaterial() {
  yield takeLatest("UPDATE_NROFPLANTS_MATERIAL", updateTestMaterial);
}

// fetching determinations / Marker/ Tests of crop
function fetchLeafDiskDeterminationsApi(action) {
  const url = `${urlConfig.getLeafDiskDeterminations}?CropCode=${
    action.cropcode
  }`;
  return axios(url);
}

function* fetchLeafDiskDeterminations(action) {
  yield put(show("fetchLeafDiskDeterminations"));

  try {
    const result = yield call(fetchLeafDiskDeterminationsApi, action);
    if (result.data) {
      yield put({
        type: "FETCH_LEAF_DISK_DETERMINATIONS_SUCCEEDED",
        data: result.data
      });
    }
    yield put(hide("fetchLeafDiskDeterminations"));
  } catch (e) {
    yield put(hide("fetchLeafDiskDeterminations"));
  }
}

export function* watchfetchLeafDiskDeterminations() {
  yield takeLatest(
    "FETCH_LEAF_DISK_DETERMINATIONS",
    fetchLeafDiskDeterminations
  );
}

//  Assign determinations / Marker/ Tests of crop
function assignLDDeterminationsApi(action) {
  const data = action.payload;
  const url = urlConfig.manageInfo;
  return axios({
    method: "POST",
    url,
    data
  });
}

function* assignLDDeterminations(action) {
  yield put(show("assignLDDeterminations"));

  try {
    const result = yield call(assignLDDeterminationsApi, action);
    if (result.data) {
      yield put({
        type: "ASSIGN_LD_DETERMINATIONS_SUCCEEDED",
        data: result.data
      });
      yield put({ type: "SET_ASSIGN_LD_DETERMINATION_SUCCEEDED_FLAG" });
    }
    yield put(hide("assignLDDeterminations"));
  } catch (e) {
    yield put(hide("assignLDDeterminations"));
  }
}

export function* watchAssignLDDeterminations() {
  yield takeLatest("ASSIGN_LD_DETERMINATIONS", assignLDDeterminations);
}

//  Assign determinations / Marker/ Tests of crop
function saveLDDeterminationsChangedApi(action) {
  const data = action.payload;
  const url = urlConfig.manageInfo;
  return axios({
    method: "POST",
    url,
    data
  });
}

function* saveLDDeterminationsChanged(action) {
  yield put(show("saveLDDeterminationsChanged"));

  try {
    const result = yield call(saveLDDeterminationsChangedApi, action);
    if (result.data) {
      yield put({
        type: "SAVE_LD_DETERMINATIONS_CHANGED_SUCCEEDED",
        data: result.data
      });
      yield put({ type: "SET_DETERMINATION_CHANGED_SAVED_FLAG" });
      yield put({ type: "RESET_ISCOLUMN_MARKER_DIRTY" });
    }
    yield put(hide("saveLDDeterminationsChanged"));
  } catch (e) {
    yield put(hide("saveLDDeterminationsChanged"));
  }
}

export function* watchSaveLDDeterminationsChanged() {
  yield takeLatest(
    "SAVE_LD_DETERMINATIONS_CHANGED",
    saveLDDeterminationsChanged
  );
}

function deleteSampleApi(action) {
  return axios({
    method: "post",
    url: urlConfig.saveLeafDiskSampleMaterial,
    data: action.payload
  });
}

function* deleteSample(action) {
  yield put(show("deleteSample"));

  try {
    yield call(deleteSampleApi, action);
    yield put({ type: "DELETE_LD_SAMPLE_SUCCEEDED" });
    yield put(hide("deleteSample"));
  } catch (e) {
    yield put(hide("deleteSample"));
  }
}
export function* watchDeleteSample() {
  yield takeLatest("DELETE_LD_SAMPLE", deleteSample);
}

//Seed Health

//get data for second tab
function fetchSeedHealthSampleDataApi(action) {
  const data = action.payload;
  return axios({
    method: "post",
    url: urlConfig.getSeedHealthSampleData,
    data
  });
}

function* fetchSeedHealthSampleData(action) {
  yield put(show("fetchSeedHealthSampleData"));
  try {
    const result = yield call(fetchSeedHealthSampleDataApi, action);
    yield put(hide("fetchSeedHealthSampleData"));
    if (result.data) {
      const { pageNumber, pageSize } = action.payload;
      yield put({
        type: "FETCH_SEED_HEALTH_SAMPLE_DATA_SUCCEEDED",
        data: result.data,
        pageInfo: { pageSize, pageNumber }
      });
    }
  } catch (e) {
    yield put(hide("fetchSeedHealthSampleData"));
    yield put({ type: "FETCH_MATERIALS_FAILED" });
  }
}
export function* watchFetchSeedHealthSampleData() {
  yield takeLatest("FETCH_SEED_HEALTH_SAMPLE_DATA", fetchSeedHealthSampleData);
}

//delete sample material from second tab
function deleteSHSampleApi(action) {
  return axios({
    method: "post",
    url: urlConfig.saveSeedHealthSampleMaterial, //saveLeafDiskSampleMaterial,
    data: action.payload
  });
}

function* deleteSHSample(action) {
  yield put(show("deleteSHSample"));

  try {
    yield call(deleteSHSampleApi, action);
    yield put({ type: "DELETE_SEED_HEALTH_SAMPLE_SUCCEEDED" });
    yield put(hide("deleteSHSample"));
  } catch (e) {
    yield put(hide("deleteSHSample"));
  }
}
export function* watchSHDeleteSample() {
  yield takeLatest("DELETE_SEED_HEALTH_SAMPLE", deleteSHSample);
}

// fetching Material determinations data for third tab
function fetchSHMaterialDeterminationsApi(action) {
  const data = { ...action.payload };
  return axios({
    method: "post",
    url: urlConfig.getSeedHealthmaterialDeterminations,
    data
  });
}

function* fetchSHMaterialDeterminations(action) {
  yield put(show("fetchSHMaterialDeterminations"));

  try {
    const result = yield call(fetchSHMaterialDeterminationsApi, action);
    if (result.data) {
      const { pageNumber, pageSize } = action.payload;
      yield put({
        type: "FETCH_SEED_HEALTH_MATERIAL_DETERMINATIONS_SUCCEEDED",
        data: result.data,
        pageInfo: {
          pageNumber,
          pageSize
        }
      });
    }
    yield put(hide("fetchSHMaterialDeterminations"));
  } catch (e) {
    yield put(hide("fetchSHMaterialDeterminations"));
  }
}

export function* watchFetchSHMaterialDeterminations() {
  yield takeLatest(
    "FETCH_SEED_HEALTH_MATERIAL_DETERMINATIONS",
    fetchSHMaterialDeterminations
  );
}

//fetch determinations for third tab
function fetchSeedHealthDeterminationsApi(action) {
  const url = `${urlConfig.getSeedHealthDeterminations}?CropCode=${
    action.cropcode
  }`;
  return axios(url);
}

function* fetchSeedHealthDeterminations(action) {
  yield put(show("fetchSeedHealthDeterminations"));

  try {
    const result = yield call(fetchSeedHealthDeterminationsApi, action);
    if (result.data) {
      yield put({
        type: "FETCH_SEED_HEALTH_DETERMINATIONS_SUCCEEDED",
        data: result.data
      });
    }
    yield put(hide("fetchSeedHealthDeterminations"));
  } catch (e) {
    yield put(hide("fetchSeedHealthDeterminations"));
  }
}

export function* watchfetchSeedHealthDeterminations() {
  yield takeLatest(
    "FETCH_SEED_HEALTH_DETERMINATIONS",
    fetchSeedHealthDeterminations
  );
}

//Update QR
function saveSHDeterminationsChangedApi(action) {
  const data = action.payload;
  const url = urlConfig.seedHealthManageInfo;
  return axios({
    method: "POST",
    url,
    data
  });
}

function* saveSHDeterminationsChanged(action) {
  yield put(show("saveSHDeterminationsChanged"));

  try {
    const result = yield call(saveSHDeterminationsChangedApi, action);
    if (result.data) {
      yield put({
        type: "SAVE_SEED_HEALTH_DETERMINATIONS_CHANGED_SUCCEEDED",
        data: result.data
      });
      yield put({ type: "SET_DETERMINATION_CHANGED_SAVED_FLAG" });
    }
    yield put(hide("saveSHDeterminationsChanged"));
  } catch (e) {
    yield put(hide("saveSHDeterminationsChanged"));
  }
}

export function* watchSaveSHDeterminationsChanged() {
  yield takeLatest(
    "SAVE_SEED_HEALTH_DETERMINATIONS_CHANGED",
    saveSHDeterminationsChanged
  );
}

//Assign/Unassign markers
function assignSHDeterminationsApi(action) {
  const data = action.payload;
  const url = urlConfig.seedHealthManageInfo;
  return axios({
    method: "POST",
    url,
    data
  });
}

function* assignSHDeterminations(action) {
  yield put(show("assignSHDeterminations"));

  try {
    const result = yield call(assignSHDeterminationsApi, action);
    if (result.data) {
      yield put({
        type: "ASSIGN_SEED_HEALTH_DETERMINATIONS_SUCCEEDED",
        data: result.data
      });
      yield put({ type: "SET_ASSIGN_SEED_HEALTH_DETERMINATION_SUCCEEDED_FLAG" });
    }
    yield put(hide("assignSHDeterminations"));
  } catch (e) {
    yield put(hide("assignSHDeterminations"));
  }
}

export function* watchAssignSHDeterminations() {
  yield takeLatest("ASSIGN_SEED_HEALTH_DETERMINATIONS", assignSHDeterminations);
}

//Export to Excel
function exportToExcelSHApi(testID) {
  return axios({
    method: "get",
    url: urlConfig.seedHealthExportToExcel,
    responseType: "arraybuffer",
    headers: {
      Accept: "application/vnd.ms-excel"
    },
    params: { testID }
  });

}

function* exportToExcelSH(action) {
  yield put(show("exportToExcelSH"));

  try {
    const { testID, fileTitle } = action;
    const response = yield call(exportToExcelSHApi, testID);
    if (response.status === 200) {
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement("a");
      link.href = url;
      const fn = fileTitle || action.testID;
      link.setAttribute("download", `${fn}.xlsx`);
      document.body.appendChild(link);
      link.click();
    }

    yield put(hide("exportToExcelSH"));
  } catch (e) {
    yield put(hide("exportToExcelSH"));
  }
}

export function* watchExportToExcelSH() {
  yield takeLatest("POST_SEED_HEALTH_EXPORT_TO_EXCEL", exportToExcelSH);
}

//Send to ABS
function SendToABSSHApi(action) {
  const { testID } = action;

  return axios({
    method: "POST",
    url: urlConfig.seedHealthSendToABS,
    params: {
      testID
    }
  });
}

function* SendToABSSH(action) {
  yield put(show("SendToABSSH"));

  try {
    const result = yield call(SendToABSSHApi, action);
    const { statusCode, testID } = result.data;

    if (statusCode === 500) {
      yield put({
        type: "ROOT_STATUS",
        statusCode: statusCode,
        testID: testID,
      });

      yield put(
        notificationSuccessTimer("Successfully sent data to ABS.")
      );
    } else {
      yield put({
        type: "NOTIFICATION_SHOW",
        status: true,
        message: "Error sending data to ABS",
        messageType: 2,
        notificationType: 0,
        code: 101
      });
    }

    yield put(hide("SendToABSSH"));
  } catch (e) {
    yield put(hide("SendToABSSH"));
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

export function* watchSendToABSSH() {
  yield takeLatest("POST_SEED_HEALTH_SEND_TO_ABS", SendToABSSH);
}