import { call, takeLatest, put } from "redux-saga/effects";

import { getRDTtestOverviewApi, getRDToverviewExcelApi } from "./api";
import { FETCH_RDT_OVERVIEW } from "./constant";
import { rdtTotal, rdtPage, rdtDataBulk, filterRDTaddBluk } from "./action";
import { show, hide } from "../../helpers/helper";

function* getRDToverview(action) {
  try {
    yield put(show("getRDToverview"));
    const { pageNumber, pageSize, filter, active } = action;

    const result = yield call(
      getRDTtestOverviewApi,
      pageNumber,
      pageSize,
      filter,
      active
    );

    const { total, data } = result.data;
    yield put(filterRDTaddBluk(filter));
    yield put(rdtDataBulk(data));
    yield put(rdtTotal(total));
    yield put(rdtPage(pageNumber));
    yield put(hide("getRDToverview"));
  } catch (err) {
    yield put(rdtDataBulk([]));
    yield put(rdtTotal(0));
    yield put(rdtPage(1));
    yield put(hide("getRDToverview"));
  }
}

export function* watchGetRDToverview() {
  yield takeLatest(FETCH_RDT_OVERVIEW, getRDToverview);
}

function* rdtOverviewExcel(action) {
  try {
    const { testID, testName, isMarkerScore } = action;
    let markerScore = isMarkerScore ? true : false;
    let traitScore = !markerScore;
    const response = yield call(getRDToverviewExcelApi, testID, markerScore, traitScore);
    if (response.status === 200) {
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement("a");
      link.href = url;
      const fileName = testName || testID;
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
export function* watchRDToverviewExcel() {
  yield takeLatest("REQUEST_RDT_OVERVIEW_EXCEL", rdtOverviewExcel);
}
