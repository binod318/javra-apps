import { call, put, takeLatest, select } from "redux-saga/effects";
import axios from "axios";
import urlConfig from "../../../urlConfig";
import { notificationSuccess } from "../../../saga/notificationSagas";
import { show, hide } from "../../../helpers/helper";

function labOverviewApi(action) {
  const { year, periodID } = action;
  return axios({
    method: "get",
    url: urlConfig.getLabOverview,

    params: {
      year,
      periodID
    }
  });
}
function* labOverview(action) {
  try {
    yield put(show("labOverview"));

    const result = yield call(labOverviewApi, action);
    const { data } = result;
    yield put({ type: "LAB_OVERVIEW_DATA_ADD", data });
    yield put({ type: "LABOVERVIEW_REFRESH" });
    yield put(hide("labOverview"));
  } catch (e) {
    yield put(hide("labOverview"));
    if (e.response.data) {
      const error = e.response.data;
      yield put({
        type: "NOTIFICATION_SHOW",
        status: true,
        message: error.message,
        messageType: 4, // error.errorType,
        notificationType: 0,
        code: error.code
      });
    }
  }
}
export function* watchLabOverview() {
  yield takeLatest("LAB_OVERVIEW_DATA_FETCH", labOverview);
}

function slotEditApi(
  slotID,
  plannedDate,
  expectedDate,
  nrOfPlates,
  nrOfTests,
  forced
) {
  return axios({
    method: "put",
    url: urlConfig.moveSlotPeriod,

    data: {
      slotID,
      plannedDate,
      expectedDate,
      nrOfPlates,
      nrOfTests,
      forced
    }
  });
}
function* slotEdit(action) {
  try {
    yield put(show("slotEdit"));

    const {
      slotID,
      plannedDate,
      expectedDate,
      nrOfPlates,
      nrOfTests,
      currentYear,
      forced
    } = action;
    const result = yield call(
      slotEditApi,
      slotID,
      plannedDate,
      expectedDate,
      nrOfPlates,
      nrOfTests,
      forced
    );
    const {
      data: { success, message }
    } = result;
    if (success) {
      yield put({ type: "LAB_OVERVIEW_DATA_FETCH", year: currentYear });
      yield put({ type: "LABOVERVIEW_SUBMIT", flag: true });
      const loList = yield select(state => state.laboverview.data);
      const tname = loList.filter(l => l.slotID === slotID);
      yield put(
        notificationSuccess(`Slot ${tname[0].slotName} was successfully moved.`)
      );
    } else {
      yield put({
        type: "LABOVERVIEW_ERROR",
        message,
        submit: false,
        forced: true
      });
    }
    yield put(hide("slotEdit"));
  } catch (e) {
    yield put(hide("slotEdit"));
    if (e.response.data) {
      const error = e.response.data;
      yield put({
        type: "LABOVERVIEW_SUBMIT",
        flag: true
      });
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
export function* watchLabSlotEdit() {
  yield takeLatest("SLOT_EDIT", slotEdit);
}

function postLabOverviewExcel(periodID, year, filter) {
  return axios({
    method: "post",
    responseType: "arraybuffer",
    url: urlConfig.postLabOverviewExcel,
    headers: {
      Accept: "application/vnd.ms-excel"
    },
    data: {
      periodID,
      year,
      filter
    }
  });
}

function* labOverviewExcel(action) {
  try {
    const { periodID, year, filter } = action;
    const response = yield call(postLabOverviewExcel, periodID, year, filter);
    if (response.status === 200) {
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement("a");
      link.href = url;
      const fileName =
        periodID && year ? `${periodID}_${year}` : "lab_overview_export";
      link.setAttribute("download", `${fileName}.xlsx`);
      document.body.appendChild(link);
      link.click();
    }
  } catch (e) {
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

export function* watchLabOverviewExcel() {
  yield takeLatest("EXPORT_LABOVERVIEW", labOverviewExcel);
}
