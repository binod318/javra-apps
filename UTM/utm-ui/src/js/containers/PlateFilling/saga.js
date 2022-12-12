/**
 * Created by sushanta on 3/5/18.
 */
import { call, put, takeLatest, select } from "redux-saga/effects";
import axios from "axios";
import urlConfig from "../../urlConfig";
import {
  noInternet,
  notificationMsg,
  notificationSuccess
} from "../../saga/notificationSagas";
import {
  createReplicaApi,
  deleteDeadMaterialsApi,
  fetchWellApi,
  getStatusListApi,
  deleteRowApi,
  undoDeadApi,
  deleteReplicateApi,
  getWellTypeApi,
  saveDBApi,
  reservePlateApi,
  undoFixedPositionApi,
  postPlateFillingExcelApi,
  getPlateFillingTotalMarkerApi
} from "./api";

import { show, hide } from "../../helpers/helper";

function getPlateFillingPageSize(store) {
  return store.plateFilling.total.pageSize || 200;
}
function getPlantFilter(store) {
  return store.plateFilling.filter || [];
}

function* createReplica({ data }) {
  try {
    yield put(show("createReplica"));

    const response = yield call(createReplicaApi, data);
    if (response.status === 200) {
      const state = yield select();
      const pageSize = getPlateFillingPageSize(state);
      const filterF = getPlantFilter(state);
      // consoleLog(42, 'createReplica');
      yield put({
        type: "PLATEDATA_FETCH",
        testID: data.testID,
        pageNumber: 1,
        pageSize,
        filter: filterF
      });
      yield put({ type: "SIZE_PLATE_RECORD", pageSize });
      yield put({ type: "REQUEST_TOTAL_MARKER", testID: data.testID });
    } else {
      yield put(
        notificationMsg({
          message: "Replicas could not be created. Try Again Later"
        })
      );
    }
    yield put(hide("createReplica"));
  } catch (e) {
    yield put(hide("createReplica"));
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
export function* watchCreateReplicaDispatch() {
  yield takeLatest("CREATE_REPLICA", createReplica);
}

function* deleteDeadMaterials(action) {
  try {
    yield put(show("deleteDeadMaterials"));

    const result = yield call(deleteDeadMaterialsApi, action);
    if (result.data) {
      yield put(hide("deleteDeadMaterials"));
      const state = yield select();
      const pageSize = getPlateFillingPageSize(state);
      // consoleLog(87, 'deleteDeadMaterials');
      yield put({
        type: "PLATEDATA_FETCH",
        testID: action.testID,
        pageNumber: 1,
        pageSize,
        filter: []
      });
      yield put({ type: "REQUEST_TOTAL_MARKER", testID: action.testID });
      yield put({ type: "SIZE_PLATE_RECORD", pageSize });
    } else {
      yield put(hide("deleteDeadMaterials"));
      yield put(
        notificationMsg({
          message: "Dead Materials could not be removed. Try Again Later"
        })
      );
    }
  } catch (e) {
    yield put(hide("deleteDeadMaterials"));
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
export function* watchDeleteDeadMaterialsDispatch() {
  yield takeLatest("REQUEST_DEAD_MATERIALS_DELETE", deleteDeadMaterials);
}

export function* fetchWell(action) {
  try {
    const result = yield call(fetchWellApi, action);
    yield put({
      type: "WELL_ADD",
      data: result.data
    });
  } catch (e) {
    e;
  }
}
export function* watchFetchWell() {
  yield takeLatest("FETCH_WELL", fetchWell);
}

export function* wetchStatusList() {
  try {
    const result = yield call(getStatusListApi);
    if (result.data) {
      yield put({
        type: "STORE_STATUS",
        data: result.data
      });
    }
  } catch (e) {
    e;
  }
}
export function* watchFetchStatusList() {
  yield takeLatest("FETCH_STATULSLIST", wetchStatusList);
}

export function fetchPlateDataApi(action) {
  return axios({
    method: "post",
    url: urlConfig.getDetermination,

    data: {
      testID: action.testID,
      filter: action.filter,
      pageNumber: action.pageNumber,
      pageSize: action.pageSize
    }
  });
}
function* fetchPlateData(action) {
  try {
    // yield put({ type: 'LOADER_SHOW' });
    yield put(show("fetchPlateData - plateFilling.saga.js"));

    const result = yield call(fetchPlateDataApi, action);

    const { data } = result;
    // const state = yield select();

    yield put({ type: "DATA_FILLING_BULK_ADD", data: data.data.data });
    yield put({ type: "COLUMN_FILLING_BULK_ADD", data: data.data.columns });
    yield put({ type: "TOTAL_PLATE_RECORD", total: data.total });
    yield put({
      type: "FILTERED_TOTAL_PLATE_RECORD",
      grandTotal: data.totalCount
    });
    yield put({ type: "SIZE_PLATE_RECORD", pageSize: action.pageSize });
    yield put({ type: "PAGE_PLATE_RECORD", pageNumber: action.pageNumber });
    // yield put({ type: 'LOADER_HIDE' });

    /**
     * TODO below line is quick fix loader set to zero
     * need to check why its not changing itself to zero
     */
    // yield put({ type: 'LOADER_RESET' });
    yield put(hide("fetchPlateData - plateFilling.saga.js"));
  } catch (e) {
    yield put(hide("fetchPlateData - plateFilling.saga.js"));
    // yield put({ type: 'LOADER_HIDE' });
    yield put({
      type: "DATA_FILLING_BULK_ADD",
      data: []
    });
    yield put({
      type: "COLUMN_FILLING_BULK_ADD",
      data: []
    });
    yield put({
      type: "TOTAL_PLATE_RECORD",
      total: 0
    });
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}
export function* watchFetchPlateData() {
  yield takeLatest("PLATEDATA_FETCH", fetchPlateData);
}

function* deleteRow(action) {
  try {
    // yield put({ type: 'LOADER_SHOW' });

    const result = yield call(deleteRowApi, action);
    if (result.data) {
      yield put({
        type: "DATA_ROW_DELETE",
        wellIDs: action.wellIDs,
        testID: action.testID,
        wellTypeID: result.data.wellTypeID
      });
      yield put({
        type: "ROOT_STATUS",
        statusCode: result.data.statusCode
      });
    }
    // yield put({ type: 'LOADER_HIDE' });
  } catch (e) {
    // yield put({ type: 'LOADER_HIDE' });
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}
export function* watchDeleteRow() {
  yield takeLatest("REQUEST_DATA_DELETE", deleteRow);
}

function* undoDead(action) {
  try {
    // yield put({ type: 'LOADER_SHOW' });

    const result = yield call(undoDeadApi, action);

    if (result.status === 200) {
      yield put({
        type: "DATA_UNDO_DEAD",
        wellIDs: action.wellIDs,
        testID: action.testID,
        wellTypeID: result.data.wellTypeID
      });
    }
    // yield put({ type: 'LOADER_HIDE' });
  } catch (e) {
    // yield put({ type: 'LOADER_HIDE' });
    e;
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}
export function* watchUndoDead() {
  yield takeLatest("REQUEST_UNDO_DELETE", undoDead);
}

function* deleteReplicate(action) {
  try {
    // yield put({ type: 'LOADER_SHOW' });

    const result = yield call(deleteReplicateApi, action);

    if (result) {
      // const crop = yield select(state => state.user.selectedCrop || '');
      // const breedingStation = yield select(state => state.breedingStation.selected || '');
      crop, breedingStation;
      const testID = yield select(
        state => state.plateFilling.testsLookup.selected.testID
      );
      const wellsPerPlate = yield select(
        state => state.plateFilling.testsLookup.selected.wellsPerPlate
      );

      const fetchresult = yield call(fetchPlateDataApi, {
        testID: testID * 1,
        filter: [],
        pageNumber: 1,
        pageSize: wellsPerPlate
      });
      fetchresult;

      const { data } = fetchresult;
      // const state = yield select();

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
        total: data.totalcount
      });
      yield put({
        type: "FILTERED_TOTAL_PLATE_RECORD",
        grandTotal: data.total
      });
      yield put({
        type: "SIZE_PLATE_RECORD",
        pageSize: wellsPerPlate
      });
      yield put({
        type: "PAGE_PLATE_RECORD",
        pageNumber: 1
      });
      // yield put({
      //   type: 'DATA_REMOVE_REPLICA',
      //   wellID: action.wellID
      // });
    }
    // yield put({ type: 'LOADER_HIDE' });
  } catch (e) {
    // yield put({ type: 'LOADER_HIDE' });
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
export function* watchDeleteReplicate() {
  yield takeLatest("REQUEST_DELETE_REPLICATE", deleteReplicate);
}

export function* fetchWellType() {
  try {
    // yield put({ type: 'LOADER_SHOW'});
    const result = yield call(getWellTypeApi);
    yield put({
      type: "STORE_WELLTYPEID",
      data: result.data
    });
    // yield put({ type: 'LOADER_HIDE' });
  } catch (e) {
    // yield put({ type: 'LOADER_HIDE' });
  }
}
export function* watchFetchWellType() {
  yield takeLatest("FETCH_GETWELLTYPEID", fetchWellType);
}

function* saveDB(action) {
  try {
    const result = yield call(saveDBApi, action);
    const { data } = result;

    if (data) {
      yield put(notificationSuccess("Save to DB was success."));
    } else {
      yield put(noInternet);
    }
  } catch (e) {
    yield put(notificationMsg(e.response.data));
  }
}
export function* watchActionSaveDB() {
  yield takeLatest("ACTION_SAVE_DB", saveDB);
}

function* reservePlate(action) {
  try {
    yield put({ type: "RPBDisable" });

    const result = yield call(reservePlateApi, action);

    const { data } = result;
    if (data && data.success) {
      yield put({
        type: "ROOT_STATUS",
        statusCode: result.data.statusCode,
        testID: action.testID
      });
    }
    else {
      const { errors, message: warningMessage } = data;
      const obj = {};
      if (warningMessage.length > 0) {
        // ///////////
        // WARNING //
        // ///////////
        yield put({ type: "RESERVE_PLATES_WARNING", warningMessage });
      } else {
        // ERROR
        obj.message = errors;
        yield put(notificationMsg(obj));
      }

      //Enable ReservePlates button
      if(action.forced)
        yield put({ type: "RPBEnable" });
    }
    // yield put({ type: 'RPBEnable' });
    // yield put(notificationSuccess('Confirm request successfully.'));
  } catch (e) {
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put({ type: "RPBEnable" });
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}
export function* watchReservePlate() {
  yield takeLatest("REQUEST_RESERVE_PLATE", reservePlate);
}

function* undoFixedPosition(action) {
  try {
    const pageSize = yield select(state => state.plateFilling.total.pageSize);
    const result = yield call(undoFixedPositionApi, action);

    if (result.data) {
      // service return only true
      yield put({
        type: "PAGE_PLATE_RECORD",
        pageNumber: 1
      });
      // consoleLog(428, 'undoFixedPosition');
      yield put({
        type: "PLATEDATA_FETCH",
        testID: action.testID,
        filter: [],
        pageNumber: 1,
        pageSize
      });
      yield put({
        type: "FETCH_WELL",
        testID: action.testID
      });

      yield put(notificationSuccess("Success, Undo fixed position."));
    }
  } catch (e) {
    e;
    yield put(notificationMsg(e.response.data));
  }
}
export function* watchUndoFixedPosition() {
  yield takeLatest("REQUEST_UNDO_FIXEDPOSITION", undoFixedPosition);
}

function* plateFillingExcel(action) {
  try {
    yield put(show("plateFillingExcel"));

    const testsLookup = yield select(
      state => state.plateFilling.testsLookup.list
    );

    const { testID, withControlPosition } = action;
    let fileName = "newTest";
    testsLookup.map(t => {
      if (t.testID === testID) {
        fileName = t.testName;
      }
      return null;
    });
    const response = yield call(
      postPlateFillingExcelApi,
      testID,
      withControlPosition
    );

    if (response.status === 200) {
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement("a");
      link.href = url;
      const fn = fileName || action.testID;
      // link.setAttribute('download', `C&T_Markers_${fn}.xlsx`);
      link.setAttribute("download", `${fn}.xlsx`);
      document.body.appendChild(link);
      link.click();
    }

    yield put(hide("plateFillingExcel"));
  } catch (e) {
    yield put(hide("plateFillingExcel"));
    const { data } = e.response;
    const decodedString = String.fromCharCode.apply(null, new Uint8Array(data));
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
export function* watchPlateFillingExcel() {
  yield takeLatest("REQUEST_PLATEFILLIG_EXCEL", plateFillingExcel);
}

function* plateFillingTotalMarker(action) {
  try {
    const result = yield call(getPlateFillingTotalMarkerApi, action.testID);

    if (result.status === 200) {
      yield put({
        type: "ADD_TOTAL_MARKER",
        total: result.data
      });
      // yield put(notificationSuccess('Success, Undo fixed position.'));
    }
  } catch (e) {
    e;
    yield put(notificationMsg(e.response.data));
  }
}
// getPlateFillingTotalMarkerApi
export function* watchPlateFillingTotalMarker() {
  yield takeLatest("REQUEST_TOTAL_MARKER", plateFillingTotalMarker);
}
