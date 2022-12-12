import { call, put, takeLatest, select } from "redux-saga/effects";
import axios from "axios";
import urlConfig from "../../../urlConfig";
import { notificationSuccessTimer } from "../../../saga/notificationSagas";
import { show, hide } from "../../../helpers/helper";

function labOverviewApi(action) {
  const { year, periodID, siteID, filter } = action;
  return axios({
    method: "post",
    url: urlConfig.getLabOverviewLeafDisk,

    data: {
      year,
      periodID,
      siteID,
      filter
    }
  });
}
function* labOverviewLeafDisk(action) {
  try {
    yield put(show("labOverview"));

    const result = yield call(labOverviewApi, action);
    const { data, columns } = result.data;
    yield put({ type: "LEAF_DISK_LAB_OVERVIEW_DATA_ADD", data });
    yield put({ type: "LEAF_DISK_LAB_OVERVIEW_COLUMN_ADD", columns });
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
export function* watchLDLabOverview() {
  yield takeLatest("LEAF_DISK_LAB_OVERVIEW_DATA_FETCH", labOverviewLeafDisk);
}

function slotEditApi(
  slotID,
  plannedDate,
  nrOfTests,
  forced
) {
  return axios({
    method: "put",
    url: urlConfig.updateSlotPeriodLeafDisk,

    data: {
      slotID,
      plannedDate,
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
      nrOfTests,
      currentYear,
      forced
    } = action;
    const result = yield call(
      slotEditApi,
      slotID,
      plannedDate,
      nrOfTests,
      forced
    );
    const {
      data: { success, message }
    } = result;
    if (success) {
      yield put({ type: "LEAF_DISK_LAB_OVERVIEW_DATA_FETCH", year: currentYear });
      yield put({ type: "LABOVERVIEW_SUBMIT", flag: true });
      const loList = yield select(state => state.ldlaboverview.data);
      const tname = loList.filter(l => l.slotID === slotID);
      yield put(
        notificationSuccessTimer(`Slot ${tname[0].slotName} was successfully udpated.`)
        //yield put(notificationSuccessTimer("Remark successfully saved."))
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
export function* watchLDLabSlotEdit() {
  yield takeLatest("LEAF_DISK_SLOT_EDIT", slotEdit);
}

function postLabOverviewExcel(periodID, year, siteID, filter) {
  return axios({
    method: "post",
    responseType: "arraybuffer",
    url: urlConfig.postLabOverviewExcelLeafDisk,
    headers: {
      Accept: "application/vnd.ms-excel"
    },
    data: {
      periodID,
      year,
      siteID,
      filter
    }
  });
}

function* labOverviewExcel(action) {
  try {
    const { periodID, year, siteID, filter } = action;
    const response = yield call(postLabOverviewExcel, periodID, year, siteID, filter);
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

export function* watchLDLabOverviewExcel() {
  yield takeLatest("LEAF_DISK_EXPORT_LABOVERVIEW", labOverviewExcel);
}
