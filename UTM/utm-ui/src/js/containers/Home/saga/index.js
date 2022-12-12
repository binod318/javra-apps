import { call, takeLatest, put, select } from "redux-saga/effects";
import {
  noInternet,
  notificationMsg,
  notificationSuccess,
  notificationSuccessTimer
} from "../../../saga/notificationSagas";
import {
  fetchFileListApi,
  fetchTestTypeApi,
  fetchMaterialTypeApi,
  fetchTestProtocolApi,
  fetchMaterialStateApi,
  fetchContainerTypeApi,
  fetchAssignDataApi,
  fetchMarkerApi,
  fetchAssignFilterDataApi,
  fetchBreedingApi,
  fetchImportSourceApi,
  postSaveNrOfSamplesApi,
  postDeleteTestApi,
  fetchS2SApi,
  saveS2SMarkerApi,
  addToS2SApi,
  fetchS2SFillRateApi,
  postUploadS2SApi,
  postProjectListApi,
  postS2SmanageMarkerApi,
  fetchCNTApi,
  saveCNTMarkerApi,
  fetchCNTDataWithMarkersApi,
  postCNTManageMarkersApi,
  postCNTManageInfoApi,
  getCNTExportApi,
  getApprovedSlotsApi,
  postRDTMaterialWithTestsApi,
  saveRDTAssignTestsApi,
  getRDTMaterialStateApi,
  postRDTrequestSampleTestApi,
  postRDTupdateRequestSampleTestApi,
  postRDTprintApi,
  getMasterGetSitesApi,
  fetchUserCropsApi,
  fetchConfigurationListApi,
  postLeafDiskrequestSampleTestApi,
  leafDiskPrintLabelApi,
  seedHealthPrintLabelApi
} from "../api/index";

import { show, hide } from "../../../helpers/helper";

function* fetchTestType(action) {
  try {
    yield put(show("fetchTestType"));

    const result = yield call(fetchTestTypeApi);
    const { data } = result;
    yield put({ type: "TESTTYPE_ADD", data });

    // if testType is not selected :: default to first test
    if (action.testTypeID === "") {
      yield put({
        type: "TESTTYPE_SELECTED",
        id: data[0].testTypeID
      });
    }
    yield put(hide("fetchTestType"));
  } catch (e) {
    yield put(hide("fetchTestType"));
    yield put(noInternet);
  }
}
export function* watchFetchTestType() {
  yield takeLatest("FETCH_TESTTYPE", fetchTestType);
}

function* fetchMaterialType() {
  try {
    yield put(show("fetchMaterialType"));

    const result = yield call(fetchMaterialTypeApi);
    const { data } = result;
    if (result.status === 200) {
      yield put({ type: "STORE_MATERIAL_TYPE", data });
    }
    yield put(hide("fetchMaterialType"));
  } catch (e) {
    yield put(hide("fetchMaterialType"));
    yield put(noInternet);
  }
}
export function* watchFetchMaterialType() {
  yield takeLatest("FETCH_MATERIAL_TYPE", fetchMaterialType);
}

function* fetchTestProtocol() {
  try {
    yield put(show("fetchTestProtocol"));

    const result = yield call(fetchTestProtocolApi);

    const { data } = result;
    if (result.status === 200) {
      yield put({ type: "STORE_TEST_PROTOCOL", data });
    }
    yield put(hide("fetchTestProtocol"));
  } catch (e) {
    yield put(hide("fetchTestProtocol"));
    yield put(noInternet);
  }
}
export function* watchFetchTestProtocol() {
  yield takeLatest("FETCH_TEST_PROTOCOL", fetchTestProtocol);
}

function* fetchMaterialState() {
  try {
    yield put(show("fetchMaterialState"));

    const result = yield call(fetchMaterialStateApi);
    const { data, status } = result;
    if (status === 200) {
      yield put({ type: "STORE_MATERIAL_STATE", data });
    }
    yield put(hide("fetchMaterialState"));
  } catch (e) {
    yield put(hide("fetchMaterialState"));
    yield put(noInternet);
  }
}
export function* watchFetchMaterialState() {
  yield takeLatest("FETCH_MATERIAL_STATE", fetchMaterialState);
}

function* fetchContainerType() {
  try {
    yield put(show("fetchContainerType"));

    const result = yield call(fetchContainerTypeApi);
    const { data, status } = result;
    if (status === 200) {
      yield put({ type: "STORE_CONTAINER_TYPE", data });
    }
    yield put(hide("fetchContainerType"));
  } catch (e) {
    yield put(hide("fetchContainerType"));
    yield put(noInternet);
  }
}
export function* watchFetchContainerType() {
  yield takeLatest("FETCH_CONTAINER_TYPE", fetchContainerType);
}

function* fetchAssignData(action) {
  try {
    yield put(show("fetchAssignData"));

    const result = yield call(fetchAssignDataApi, action.file);
    const { data } = result;

    const { testTypeID } = action.file;
    let markers = [];

    if(testTypeID != 9 && testTypeID != 10) {
      const result1 = yield call(fetchMarkerApi, action.file);
      markers = result1.data;
    }

    if (data.success) {
      // clear filter,
      yield put({ type: "FILTER_CLEAR" });
      yield put({ type: "DATA_BULK_ADD", data: data.dataResult.data });
      yield put({ type: "COLUMN_BULK_ADD", data: data.dataResult.columns });
      yield put({ type: "TOTAL_RECORD", total: data.total });
      yield put({ type: "FILTERED_TOTAL_RECORD", grandTotal: data.totalCount });

      yield put({ type: "PAGE_RECORD", pageNumber: action.file.pageNumber });
      yield put({ type: "TESTTYPE_SELECTED", id: action.file.testTypeID });
      yield put({ type: "DEFAULT_SIZE_RECORD"});

      //Only for Leafdisk & Seedhealth
      if (testTypeID === 9 || testTypeID === 10) {
        const leafDiskMaterialMap = {};
        //for #plants
        const refresh = yield select(
          state => !state.assignMarker.materials.refresh
        );

        data.dataResult.data.forEach(row => {
          leafDiskMaterialMap[`${row.materialID}-#plants`] = {
            '#plants': row['#plants'] || "",
            changed: false,
            newState: row['#plants'] || ""
          };
        });

        yield put({ type: "ADD_LDMATERIAL_MAP", leafDiskMaterialMap, refresh });
      }
    }
    const newMarker = markers.map(d => ({ ...d, selected: false }));
    yield put({ type: "MARKER_BULK_ADD", data: newMarker });
    yield put({ type: "SAMPLE_NUMBER_REST" });

    yield put(hide("fetchAssignData"));
  } catch (e) {
    yield put(hide("fetchAssignData"));
    // make blank when get error in fetch data
    yield put({ type: "MARKER_BULK_ADD", data: [] });
    yield put({ type: "DATA_BULK_ADD", data: [] });
    yield put({ type: "COLUMN_BULK_ADD", data: [] });
    yield put({ type: "TOTAL_RECORD", total: 0 });
    yield put(noInternet);
  }
}
export function* watchFetchAssignData() {
  yield takeLatest("ASSIGNDATA_FETCH", fetchAssignData);
}

function* fetchAssignFilterData(action) {
  try {
    yield put(show("fetchAssignFilterData"));
    const { testTypeID } = action;

    const result = yield call(fetchAssignFilterDataApi, action);
    const { data } = result;
    if (data.success) {
      yield put({ type: "FILTER_ADD_BULK", filter: action.filter });
      yield put({ type: "DATA_BULK_ADD", data: data.dataResult.data });
      yield put({ type: "COLUMN_BULK_ADD", data: data.dataResult.columns });
      yield put({ type: "TOTAL_RECORD", total: data.total });
      yield put({ type: "FILTERED_TOTAL_RECORD", grandTotal: data.totalCount });

      yield put({ type: "PAGE_RECORD", pageNumber: 1 });

      //Only for Leafdisk & Seedhealth
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
    yield put(hide("fetchAssignFilterData"));
  } catch (e) {
    yield put(hide("fetchAssignFilterData"));
  }
}
export function* watchFetchAssignFilterData() {
  yield takeLatest("FETCH_FILTERED_DATA", fetchAssignFilterData);
}

function* fetchAssignClearData(action) {
  try {
    yield put(show("fetchAssignClearData"));
    const { testTypeID } = action;

    const result = yield call(fetchAssignFilterDataApi, action);
    const { data } = result;
    if (data.success) {
      yield put({ type: "DATA_BULK_ADD", data: data.dataResult.data });
      yield put({ type: "COLUMN_BULK_ADD", data: data.dataResult.columns });
      yield put({ type: "TOTAL_RECORD", total: data.total });
      yield put({ type: "FILTER_CLEAR" });
      // changeing page to one
      yield put({ type: "PAGE_RECORD", pageNumber: 1 });
      yield put({ type: "DEFAULT_SIZE_RECORD"});

      //Only for Leafdisk & Seedhealth
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

    yield put(hide("fetchAssignClearData"));
  } catch (e) {
    yield put(hide("fetchAssignClearData"));
  }
}
export function* watchFetchAssignClearData() {
  yield takeLatest("FETCH_CLEAR_FILTER_DATA", fetchAssignClearData);
}

function* fetchFileList(action) {
  try {
    const { breeding, crop, testTypeMenu } = action;
    const result = yield call(fetchFileListApi, breeding, crop, testTypeMenu);

    // TODO :: check impack and imporve
    // clear data or not
    // if (action.empty === false) {
    // }
    /*
    if (action.empty !== false) {
      yield put({  type: 'DATA_BULK_ADD', data: [] });
      yield put({  type: 'COLUMN_BULK_ADD', data: [] });
    }
    */
    yield put({ type: "FILELIST_ADD", data: result.data });
  } catch (e) {
    yield put(noInternet);
  }
}
export function* watchFetchFileList() {
  yield takeLatest("FILELIST_FETCH", fetchFileList);
}

function* fetchBreeding() {
  try {
    yield put(show("fetchBreeding"));

    const result = yield call(fetchBreedingApi);

    yield put({
      type: "BREEDING_STATION_STORE",
      data: result.data
    });

    yield put(hide("fetchBreeding"));
  } catch (e) {
    yield put(hide("fetchBreeding"));
    yield put(noInternet);
  }
}
export function* watchFetchBreeding() {
  yield takeLatest("FETCH_BREEDING_STATION", fetchBreeding);
}

function* fetchImportSource() {
  try {
    yield put(show("fetchImportSource"));

    const result = yield call(fetchImportSourceApi);
    if (result.status === 200) {
      yield put({ type: "ADD_SOURCE", data: result.data });
    }
    yield put(hide("fetchImportSource"));
  } catch (e) {
    yield put(hide("fetchImportSource"));
    yield put(noInternet);
  }
}
export function* watchFetchImportSource() {
  yield takeLatest("FETCH_IMPORTSOURCE", fetchImportSource);
}

function* postSaveNrOfSamples() {
  try {
    const fileID = yield select(
      state => state.assignMarker.file.selected.fileID
    );
    const noofsamples = yield select(
      state => state.assignMarker.numberOfSamples.samples
    );
    const samples = [];
    noofsamples.map(row => {
      const { materialID, nrOfSample, changed } = row;
      if (changed) {
        samples.push({ materialID, nrOfSample });
      }
      return null;
    });

    const result = yield call(postSaveNrOfSamplesApi, { fileID, samples });
    if (result.data) {
      yield put({ type: "SAMPLE_NUMBER_CHANGE_FALSE" });
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
export function* watchpostSaveNrOfSamples() {
  yield takeLatest("POST_NO_OF_SAMPLES", postSaveNrOfSamples);
}

/**
 * Saga
 */
function* postDeleteTest(action) {
  try {
    yield put(show("postDeleteTest"));
    const result = yield call(postDeleteTestApi, action.testID);

    if (result.data) {
      // ## remove table date
      yield put({ type: "RESETALL" });
      // ## remove filed from imported dropdown list
      yield put({
        type: "REMOVE_FILE_AFTER_DELETE",
        testID: action.testID
      });
    }

    yield put(hide("postDeleteTest"));

    yield put(notificationSuccessTimer(result.data));
  } catch (e) {
    yield put(hide("postDeleteTest"));

    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}
export function* watchDeletePost() {
  yield takeLatest("POST_DELETE_TEST", postDeleteTest);
}

// ## S2S SAGA START
function* fetchS2S(action) {
  try {
    yield put(show("fetchS2S"));

    const result = yield call(fetchS2SApi, action);
    if (result.data) {
      const markerMaterialMap = {};
      const scoreMaterialMap = {};
      const donerInfoMap = {};

      const determinationColumns =
        result.data.data.columns &&
        result.data.data.columns
          .filter(
            col =>
              col.traitID && col.traitID.substring(0, 2).toLowerCase() === "d_"
          )
          .map(col => col.traitID.toLowerCase());

      const scoreNumber =
        result.data.data.columns &&
        result.data.data.columns
          .filter(
            col =>
              col.traitID &&
              col.traitID.substring(0, 6).toLowerCase() === "score_"
          )
          .map(col => col.traitID.toLowerCase());

      result.data.data.data.forEach(row => {
        determinationColumns.forEach(col => {
          if (col === "d_selected") {
            markerMaterialMap[`${row.materialID}-${col}`] = {
              originalState: row.d_Selected,
              changed: false,
              newState: row.d_Selected,
              mk: row.materialKey
            };
          } else {
            markerMaterialMap[`${row.materialID}-${col}`] = {
              originalState: row[col],
              changed: false,
              newState: row[col],
              mk: row.materialKey
            };
          }
        });
        scoreNumber.forEach(col => {
          scoreMaterialMap[`${row.materialID}-${col}`] = {
            value: row[col] || "",
            changed: false,
            newState: row[col] || ""
          };
        });

        donerInfoMap[`${row.materialID}-doner`] = {
          dH0Net: row.dH0Net || "",
          requested: row.requested || "",
          transplant: row.transplant || "",
          toBeSown: row.toBeSown || "",
          projectCode: row.projectCode || "",
          changed: false
        };
      });

      yield put({
        type: "FETCH_MATERIALS_SUCCEEDED",
        materials: result.data,
        markerMaterialMap
      });

      const refresh = yield select(
        state => !state.assignMarker.materials.refresh
      );
      yield put({
        type: "ADD_SCOREMAP",
        scores: scoreMaterialMap,
        donerInfoMap,
        refresh
      });
    }
    yield put(hide("fetchS2S"));
  } catch (e) {
    yield put(hide("fetchS2S"));

    yield put({ type: "FETCH_MATERIALS_FAILED" });
  }
}
export function* watchFetchS2S() {
  yield takeLatest("FETCH_S2S", fetchS2S);
}

export function* fetchSaveS2SMarker(action) {
  try {
    yield put(show("fetchSaveS2SMarker"));

    const result = yield call(saveS2SMarkerApi, action.materialsMarkers);
    if (result.data) {
      yield put({ type: "MATERIALS_MARKER_SAVE_SUCCEEDED" });
      yield put({ type: "SUCCESS_SCOREMAP" });
      yield put({
        type: "FETCH_S2S_FILLRATE",
        testID: action.materialsMarkers.testID
      });
      yield put({ type: "MARKER_DISELECT" });
      yield put(notificationSuccessTimer("Markers are successfully assigned."));
    }
    yield put(hide("fetchSaveS2SMarker"));
  } catch (e) {
    yield put(hide("fetchSaveS2SMarker"));

    yield put({ type: "FETCH_MATERIALS_FAILED" });
  }
}
export function* watchSaveS2Smarker() {
  yield takeLatest("SAVE_S2S_MATERIAL_MARKER", fetchSaveS2SMarker);
}

function* addToS2S(action) {
  try {
    const result = yield call(addToS2SApi, action);
    yield put({ type: "FILTER_CLEAR" });
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
export function* watchAddToS2S() {
  yield takeLatest("ADD_TO_S2S", addToS2S);
}

function* fetchS2SFillRate(action) {
  try {
    const result = yield call(fetchS2SFillRateApi, action);
    if (result.status === 200) {
      yield put({
        type: "FILLRATE_INSERT",
        data: result.data
      });
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
export function* watchS2SFillRate() {
  yield takeLatest("FETCH_S2S_FILLRATE", fetchS2SFillRate);
}

function* postUploadS2S(action) {
  try {
    yield put(show("postUploadS2S"));
    const result = yield call(postUploadS2SApi, action.testID);
    if (result.status === 200) {
      yield put({ type: "RESETALL" });
      // filelistreducer reset
      yield put({ type: "RESET_ALL" });
      // testslookup rest
      yield put({ type: "TESTSLOOKUP_RESET_ALL" });

      yield put({
        type: "REMOVE_FILE_AFTER_SENDTO_3GB",
        testID: action.testID
      });
      yield put(notificationSuccess("Successfully sent to S2S."));
    }
    yield put(hide("postUploadS2S"));
  } catch (e) {
    yield put(hide("postUploadS2S"));
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}
export function* watchUploadS2S() {
  yield takeLatest("POST_S2S_UPLOAD", postUploadS2S);
}

// PROJECT LIST FETCH
// fetch
function* fetchProjectList(action) {
  try {
    yield put(show("postProjectList"));
    const result = yield call(postProjectListApi, action.crop);

    // TODO :: PROJECT LIST FETCH ACTION
    if (result.status === 200) {
      yield put({
        type: "BULK_S2S_PROJECT_LIST",
        data: result.data
      });
    }

    yield put(hide("postProjectList"));
  } catch (e) {
    yield put(hide("postProjectList"));
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}
// watch
export function* watchProjectList() {
  yield takeLatest("FETCH_S2S_PROJECT_LIST", fetchProjectList);
}

export function* postS2SmanageMarker(action) {
  try {
    yield put(show("postS2SmanageMarker"));

    yield call(postS2SmanageMarkerApi, action);
    yield put({ type: "MARKER_DISELECT" });
    yield put(notificationSuccessTimer("Markers are successfully assigned."));
    yield put(hide("postS2SmanageMarker"));
  } catch (e) {
    yield put(hide("postS2SmanageMarker"));
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}
// ## S2S SAGA END

// ## S2S SAGA START
export function* fetchCNT(action) {
  try {
    yield put(show("fetchCNT"));
    yield call(fetchCNTApi, action);
    yield put(hide("fetchCNT"));
  } catch (e) {
    yield put(hide("fetchCNT"));
    yield put({ type: "FETCH_MATERIALS_FAILED" });
  }
}

// C & T
export function* fetchSaveCNTMarker(action) {
  try {
    yield put(show("fetchSaveCNTMarker"));
    const result = yield call(saveCNTMarkerApi, action.materialsMarkers);
    if (result.status === 200) {
      yield put({ type: "MARKER_DISELECT" });
    }
    yield put(notificationSuccessTimer("Markers are successfully assigned."));
    yield put(hide("fetchSaveCNTMarker"));
  } catch (e) {
    yield put(hide("fetchSaveCNTMarker"));

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
// ## S2S SAGA START
export function* fetchCNTDataWithMarkers(action) {
  try {
    yield put(show("fetchCNTDataWithMarkers"));

    const result = yield call(fetchCNTDataWithMarkersApi, action);

    if (result.data) {
      const markerMaterialMap = {};
      const donerInfoMap = {};
      const determinationColumns =
        result.data.data.columns &&
        result.data.data.columns
          .filter(
            col =>
              col.traitID && col.traitID.substring(0, 2).toLowerCase() === "d_"
          )
          .map(col => col.traitID.toLowerCase());

      result.data.data.data.forEach(row => {
        determinationColumns.forEach(col => {
          if (col === "d_selected") {
            markerMaterialMap[`${row.materialID}-${col}`] = {
              originalState: row.d_Selected,
              changed: false,
              newState: row.d_Selected,
              mk: row.materialKey
            };
          } else {
            markerMaterialMap[`${row.materialID}-${col}`] = {
              originalState: row[col] || 0,
              changed: false,
              newState: row[col]
            };
          }
        });
        donerInfoMap[`${row.materialID}-doner`] = {
          rowID: row.rowID || "",
          net: row.net || "",
          dH1ReturnDate: row.dH1ReturnDate || "",
          requestedDate: row.requestedDate || "",
          remarks: row.remarks || "",
          requested: row.requested || "",
          transplant: row.transplant || "",
          donorNumber: row.donorNumber || "",
          processID: row.processID || "",
          labLocationID: row.labLocationID || "",
          startMaterialID: row.startMaterialID || "",
          typeID: row.typeID || "",
          changed: false
        };
      });

      yield put({
        type: "FETCH_MATERIALS_SUCCEEDED",
        materials: result.data,
        markerMaterialMap
      });

      const refresh = yield select(
        state => !state.assignMarker.materials.refresh
      );
      yield put({
        type: "ADD_SCOREMAP",
        scores: [],
        donerInfoMap,
        refresh
      });
    }

    yield put(hide("fetchCNTDataWithMarkers"));
  } catch (e) {
    yield put(hide("fetchCNTDataWithMarkers"));
  }
}

export function* postCNTMnagMarkers(action) {
  try {
    let resultStatus = false;
    let resultMarkerStatus = false;

    if (action.details.length || action.materials.length) {
      const result = yield call(postCNTManageInfoApi, action);
      if (result.status === 200) resultStatus = true;
    } else {
      resultStatus = true;
    }
    if (action.markers.length) {
      const resultMarker = yield call(postCNTManageMarkersApi, action);
      if (resultMarker.status === 200) resultMarkerStatus = true;
    } else resultMarkerStatus = true;
    if (resultStatus && resultMarkerStatus) {
      yield put({
        type: "FETCH_CNT_DATA_WITH_MARKERS",
        testID: action.testID,
        pageNumber: 1,
        pageSize: 200,
        filter: []
      });
      yield put({ type: "MARKER_DISELECT" });
      yield put({ type: "MATERIALS_MARKER_SAVE_SUCCEEDED" });
      yield put({ type: "SUCCESS_SCOREMAP" });
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

export function* getCNTExport(action) {
  try {
    yield put({ type: "LOADER_SHOW" });

    const response = yield call(getCNTExportApi, action);
    if (response.status === 200) {
      const fileName = yield select(
        state => state.assignMarker.file.selected.cropCode + "_" +
                 state.assignMarker.file.selected.breedingStationCode + "_" +
                 state.assignMarker.file.selected.fileTitle
      );
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement("a");
      link.href = url;
      const fn = fileName || action.testID;
      // link.setAttribute('download', `C&T_Markers_${fn}.xlsx`);
      link.setAttribute("download", `${fn}.xlsx`);
      document.body.appendChild(link);
      link.click();
    }

    yield put({ type: "LOADER_HIDE" });
  } catch (e) {
    yield put({ type: "LOADER_HIDE" });
    if (e.response.data) {
      const { data } = e.response;
      const decodedString = String.fromCharCode.apply(
        null,
        new Uint8Array(data)
      );
      const error = JSON.parse(decodedString);
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

export function* getApprovedSlots(action) {
  try {
    const { userSlotsOnly, slotName, testType } = action;
    const result = yield call(getApprovedSlotsApi, slotName, testType, userSlotsOnly);
    const { data, status } = result;
    if (status === 200) {
      yield put({
        type: "BULK_SLOT_LIST",
        data
      });
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
        code: error.code || ""
      });
    }
  }
}

// RDT
export function* fetchRDTMaterialWithTest(action) {
  try {
    yield put(show("fetchRDTMaterialWithTest"));

    const result = yield call(postRDTMaterialWithTestsApi, action);

    if (result.data) {
      const markerMaterialMap = {};
      const donerInfoMap = {};
      const RDTMaterialStatus = {};
      const maxSelectInfoMap = {};

      const determinationColumns =
        result.data.data.columns &&
        result.data.data.columns
          .filter(
            col =>
              col.traitID && col.traitID.substring(0, 2).toLowerCase() === "d_"
          )
          .map(col => col.traitID.toLowerCase());

      const dateColumns =
        result.data.data.columns &&
        result.data.data.columns
          .filter(
            col =>
              col.traitID &&
              col.traitID.substring(0, 5).toLowerCase() === "date_"
          )
          .map(col => col.traitID.toLowerCase());

      const maxSelect =
        result.data.data.columns &&
        result.data.data.columns
          .filter(col => col.traitID && col.traitID.indexOf("maxSelect") > -1)
          .map(col => col.traitID);

      result.data.data.data.forEach(row => {
        determinationColumns.forEach(col => {
          if (col === "d_selected") {
            markerMaterialMap[`${row.materialID}-${col}`] = {
              originalState: row.d_Selected,
              changed: false,
              newState: row.d_Selected,
              mk: row.materialKey
            };
          } else {
            markerMaterialMap[`${row.materialID}-${col}`] = {
              originalState: row[col] || 0,
              changed: false,
              newState: row[col]
            };
          }
        });
        dateColumns.forEach(col => {
          const dateValue = row[col] === null ? "" : row[col];
          donerInfoMap[`${row.materialID}-${col}`] = {
            originalState: dateValue,
            changed: false,
            newState: dateValue
          };
        });

        maxSelect.forEach(col => {
          maxSelectInfoMap[`${row.materialID}-${col}`] = {
            value: row[col] || "",
            changed: false,
            newState: row[col] || ""
          };
        });

        RDTMaterialStatus[`${row.materialID}-materialstatus`] = {
          originalState: row.materialStatus || "",
          changed: false,
          newState: row.materialStatus || ""
        };
      });

      yield put({
        type: "FETCH_MATERIALS_SUCCEEDED",
        materials: result.data,
        markerMaterialMap
      });
      yield put({
        type: "RDT_MATERIAL_STATUS_ADD",
        RDTMaterialStatus
      });

      const refresh = yield select(
        state => state.assignMarker.materials.refresh
      );
      yield put({
        type: "ADD_SCOREMAP",
        scores: [],
        donerInfoMap,
        refresh
      });

      yield put({
        type: "ADD_MAXSELECTMAP",
        scores: [],
        maxSelectInfoMap
      });
      yield put({
        type: "PAGE_RECORD",
        pageNumber: action.pageNumber
      });
      yield put({
        type: "SIZE_RECORD",
        pageSize: action.pageSize
      });
    }

    yield put(hide("fetchRDTMaterialWithTest"));
  } catch (e) {
    yield put(hide("fetchRDTMaterialWithTest"));
    if (e.response.data) {
      const error = e.response.data;
      yield put({
        type: "NOTIFICATION_SHOW",
        status: true,
        message: error.message,
        messageType: 2 || error.errorType,
        notificationType: 0,
        code: error.code
      });
    }
  }
}
export function* fetchSaveRDTAssignTests(action) {
  try {
    yield put(show("fetchSaveRDTAssignTests"));
    const result = yield call(saveRDTAssignTestsApi, action.materialsMarkers);
    if (result.status === 200) {
      yield put({ type: "MATERIALS_MARKER_SAVE_SUCCEEDED" });
      yield put({ type: "SUCCESS_SCOREMAP" });
      yield put({ type: "MARKER_DISELECT" });

      const { filter, testID } = action.materialsMarkers;
      yield put({
        type: "PAGE_RECORD",
        pageNumber: 1
      });
      yield put({
        type: "FETCH_RDT_MATERIAL_WITH_TESTS",
        testID,
        pageNumber: 1,
        pageSize: 200,
        filter
      });

      yield put(notificationSuccessTimer("Changes are successfully saved."));
    }
    yield put(hide("fetchSaveRDTAssignTests"));
  } catch (e) {
    yield put(hide("fetchSaveRDTAssignTests"));
    if (e.response.data) {
      const error = e.response.data;
      yield put({
        type: "NOTIFICATION_SHOW",
        status: true,
        message: error.message,
        messageType: 2 || error.errorType,
        notificationType: 0,
        code: error.code
      });
    }
    yield put({ type: "FETCH_MATERIALS_FAILED" });
  }
}
export function* fetchGetRDTMaterialState() {
  try {
    const result = yield call(getRDTMaterialStateApi);
    if (result.status === 200) {
      yield put({
        type: "DATA_RDT_STATUS_ADD",
        data: result.data
      });
    }
  } catch (e) {
    if (e.response.data) {
      const error = e.response.data;
      yield put({
        type: "NOTIFICATION_SHOW",
        status: true,
        message: error.message,
        messageType: 2 || error.errorType,
        notificationType: 0,
        code: error.code
      });
    }
  }
}

export function* postRdtRequestSampleTest(action) {
  try {
    yield put(show("postRdtRequestSampleTest"));
    const result = yield call(postRDTrequestSampleTestApi, action.testID);
    if (result.status === 200) {
      yield put({
        type: "ROOT_STATUS",
        testid: action.testID,
        statusCode: 200
      });
    }
    yield put(hide("postRdtRequestSampleTest"));
  } catch (e) {
    yield put(hide("postRdtRequestSampleTest"));
    if (e.response.data) {
      const error = e.response.data;
      yield put({
        type: "NOTIFICATION_SHOW",
        status: true,
        message: error.message,
        messageType: 2 || error.errorType,
        notificationType: 0,
        code: error.code
      });
    }
  }
}

export function* postRdtUpdateRequestSampleTest(action) {
  try {
    yield put(show("postRdtUpdateRequestSampleTest"));
    const result = yield call(postRDTupdateRequestSampleTestApi, action.testID);
    if (result.status === 200) {
      yield put({
        type: "ROOT_STATUS",
        testid: action.testID,
        statusCode: 200
      });
    }
    yield put(hide("postRdtUpdateRequestSampleTest"));
  } catch (e) {
    yield put(hide("postRdtUpdateRequestSampleTest"));
    if (e.response.data) {
      const error = e.response.data;
      yield put({
        type: "NOTIFICATION_SHOW",
        status: true,
        message: error.message,
        messageType: 2 || error.errorType,
        notificationType: 0,
        code: error.code
      });
    }
  }
}

export function* postRDTprint(action) {
  /**
   {
      "testID": 0,
      "materialStatus": ["string"],
      "materialDeterminations": [
        { "materialID": 0, "determinationID": 0 }
      ]
    }
   */
  try {
    yield put(show("postRDTprint"));
    const result = yield call(postRDTprintApi, action);
    if (result.status === 200 && result.data.success) {
      yield put(
        notificationSuccessTimer("Print request successfully completed.")
      );
    } else {
      yield put({
        type: "NOTIFICATION_SHOW",
        status: true,
        message: result.data.error,
        messageType: 2,
        notificationType: 0,
        code: 101
      });
    }
    /*
      // REFETCH not required
      yield put({
      testID: action.testID,
      filter: [],
      pageSize: 200,
      pageNumber: 1,
      type: 'FETCH_RDT_MATERIAL_WITH_TESTS'
    }); */
    yield put({ type: "RDT_PRINT_HIDE" });

    yield put(hide("postRDTprint"));
  } catch (e) {
    yield put({ type: "RDT_PRINT_HIDE" });
    yield put(hide("postRDTprint"));
    if (e.response.data) {
      const error = e.response.data;
      yield put({
        type: "NOTIFICATION_SHOW",
        status: true,
        message: error.message,
        messageType: 2 || error.errorType,
        notificationType: 0,
        code: error.code
      });
    }
  }
}

export function* fetchGetMasterGetSites() {
  try {
    yield put(show("fetchGetMasterGetSites"));
    const result = yield call(getMasterGetSitesApi);
    if (result.status === 200) {
      yield put({
        type: "DATA_GETSITES_ADD",
        data: result.data
      });
    }
    yield put(hide("fetchGetMasterGetSites"));
  } catch (e) {
    yield put(hide("fetchGetMasterGetSites"));
    if (e.response.data) {
      const error = e.response.data;
      yield put({
        type: "NOTIFICATION_SHOW",
        status: true,
        message: error.message,
        messageType: 2 || error.errorType,
        notificationType: 0,
        code: error.code
      });
    }
  }
}

export function* fetchUserCrops() {
  try {
    const response = yield call(fetchUserCropsApi);
    if (response && response.data) {
      yield put({
        type: "FETCH_USER_CROPS_SUCCEEDED",
        crops: response.data.map(crop => crop.cropCode)
      });
    }
  } catch (e) {
    if (e.response.data) {
      const error = e.response.data;
      yield put({
        type: "NOTIFICATION_SHOW",
        status: true,
        message: error.message,
        messageType: 2 || error.errorType,
        notificationType: 0,
        code: error.code
      });
    }
  }
}

//Leafdisk
function* fetchConfigurationList() {
  try {
    yield put(show("fetchConfigurationList"));
    const result = yield call(fetchConfigurationListApi);

    if (result.data) {
      yield put({
        type: "DATA_GETCONFIGURATION_ADD",
        data: result.data
      });
    }
    yield put(hide("fetchConfigurationList"));
  } catch (e) {
    yield put(hide("fetchConfigurationList"));
    yield put(noInternet);
  }
}

export function* watchfetchConfigurationList() {
  yield takeLatest("FETCH_CONFIGURATION_LIST", fetchConfigurationList);
}

export function* postLeafDiskRequestSampleTest(action) {
  try {
    yield put(show("postLeafDiskRequestSampleTest"));
    const result = yield call(postLeafDiskrequestSampleTestApi, action.testID);
    if (result.status === 200) {
      yield put({
        type: "ROOT_STATUS",
        testid: action.testID,
        statusCode: 500
      });
    }
    yield put(hide("postLeafDiskRequestSampleTest"));
  } catch (e) {
    yield put(hide("postLeafDiskRequestSampleTest"));
    if (e.response.data) {
      const error = e.response.data;
      yield put({
        type: "NOTIFICATION_SHOW",
        status: true,
        message: error.message,
        messageType: 2 || error.errorType,
        notificationType: 0,
        code: error.code
      });
    }
  }
}

export function* leafDiskPrintLabel(action) {
  try {
    yield put(show("leafDiskPrintLabel"));
    const result = yield call(leafDiskPrintLabelApi, action);
    const { data } = result;
    // result acc :: success, error, printerName
    if (data.success) {
      yield put(notificationSuccessTimer("Plate label queued for printing."));
    } else {
      const obj = {};
      obj.message = data.error;
      yield put(notificationMsg(obj));
    }
    yield put(hide("leafDiskPrintLabel"));
  } catch (e) {
    yield put(hide("leafDiskPrintLabel"));
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}

//SeedHealth
export function* seedHealthPrintLabel(action) {
  try {
    yield put(show("seedHealthPrintLabel"));
    const result = yield call(seedHealthPrintLabelApi, action);
    const { data } = result;
    // result acc :: success, error, printerName
    if (data.success) {
      yield put(notificationSuccessTimer("Plate label queued for printing."));
    } else {
      const obj = {};
      obj.message = data.error;
      yield put(notificationMsg(obj));
    }
    yield put(hide("seedHealthPrintLabel"));
  } catch (e) {
    yield put(hide("seedHealthPrintLabel"));
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}