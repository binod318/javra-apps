/**
 * Created by sushanta on 3/5/18.
 */
import { call, put, takeLatest, select } from "redux-saga/effects";
import axios from "axios";
import urlConfig from "../urlConfig";
import {
  noInternet,
  notificationMsg,
  notificationSuccess,
} from "./notificationSagas";

import { fetchPlateDataApi } from "../containers/PlateFilling/saga";

import { show, hide } from "../helpers/helper";

function fetchWellApi(action) {
  return axios({
    method: "get",
    url: urlConfig.getWellPosition,

    params: {
      testID: action.testID,
    },
  });
}
export function* fetchWell(action) {
  try {
    const result = yield call(fetchWellApi, action);
    yield put({
      type: "WELL_ADD",
      data: result.data,
    });
  } catch (e) {
    console.log(e);
  }
}
export function* watchFetchWell() {
  yield takeLatest("FETCH_WELL", fetchWell);
}

function getStatusListApi() {
  return axios({
    method: "get",
    url: urlConfig.getStatusList,
  });
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
  } catch (e) {}
}
export function* watchFetchStatusList() {
  yield takeLatest("FETCH_STATULSLIST", wetchStatusList);
}

function undoDeadApi(action) {
  return axios({
    method: "delete",
    url: urlConfig.delMaterialsUndo,

    data: {
      testID: action.testID,
      wellIDs: action.wellIDs,
    },
  });
}
function* undoDead(action) {
  try {
    yield put(show("undoDead"));

    const result = yield call(undoDeadApi, action);

    if (result.status === 200) {
      yield put({
        type: "DATA_UNDO_DEAD",
        wellIDs: action.wellIDs,
        testID: action.testID,
        wellTypeID: result.data.wellTypeID,
      });
    }
    yield put(hide("undoDead"));
  } catch (e) {
    yield put(hide("undoDead"));
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

function deleteReplicateApi(action) {
  return axios({
    method: "delete",
    url: urlConfig.delDeleteReplicate,

    data: {
      testID: action.testID,
      materialID: action.materialID,
      wellID: action.wellID,
    },
  });
}
function* deleteReplicate(action) {
  try {
    const result = yield call(deleteReplicateApi, action);

    if (result) {
      const testID = yield select(
        (state) => state.plateFilling.testsLookup.selected.testID
      );
      const wellsPerPlate = yield select(
        (state) => state.plateFilling.testsLookup.selected.wellsPerPlate
      );

      const fetchresult = yield call(fetchPlateDataApi, {
        testID: testID * 1,
        filter: [],
        pageNumber: 1,
        pageSize: wellsPerPlate,
      });

      const { data } = fetchresult;

      yield put({
        type: "DATA_FILLING_BULK_ADD",
        data: data.data.data,
      });
      yield put({
        type: "COLUMN_FILLING_BULK_ADD",
        data: data.data.columns,
      });
      yield put({
        type: "TOTAL_PLATE_RECORD",
        total: data.total,
      });
      yield put({
        type: "SIZE_PLATE_RECORD",
        pageSize: wellsPerPlate,
      });
      yield put({
        type: "PAGE_PLATE_RECORD",
        pageNumber: 1,
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
        code: error.code,
      });
    }
  }
}
export function* watchDeleteReplicate() {
  yield takeLatest("REQUEST_DELETE_REPLICATE", deleteReplicate);
}

function getWellTypeApi() {
  return axios({
    method: "get",
    url: urlConfig.getWellType,
  });
}
export function* fetchWellType() {
  try {
    const result = yield call(getWellTypeApi);
    yield put({
      type: "STORE_WELLTYPEID",
      data: result.data,
    });
  } catch (e) {
    console.log(e);
  }
}
export function* watchFetchWellType() {
  yield takeLatest("FETCH_GETWELLTYPEID", fetchWellType);
}

function saveDBApi(action) {
  return axios({
    method: "post",
    url: urlConfig.postWellSaveDB,

    data: {
      testID: action.testID,
      materialWell: action.materialIDs,
    },
  });
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

function reservePlateApi(action) {
  return axios({
    method: "post",
    url: urlConfig.postReservePlate,

    data: {
      testID: action.testID,
    },
  });
}
function* reservePlate(action) {
  try {
    const result = yield call(reservePlateApi, action);
    yield put({
      type: "ROOT_STATUS",
      statusCode: result.data.statusCode,
      testID: action.testID,
    });
    yield put(notificationSuccess("Confirm request successfully."));
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
export function* watchReservePlate() {
  yield takeLatest("REQUEST_RESERVE_PLATE", reservePlate);
}
