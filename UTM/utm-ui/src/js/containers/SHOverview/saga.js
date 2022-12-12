import { call, takeLatest, put } from "redux-saga/effects";

import { getSHTestOverviewApi, getSHOverviewExcelApi } from "./api";
import { FETCH_SH_OVERVIEW } from "./constant";
import { shTotal, shPage, shDataBulk, shColumnBulk, filterSHaddBluk } from "./action";
import { show, hide } from "../../helpers/helper";

function* getSHOverview(action) {
  try {
    yield put(show("getSHOverview"));
    const { pageNumber, pageSize, filter, active } = action;

    const result = yield call(
      getSHTestOverviewApi,
      pageNumber,
      pageSize,
      filter,
      active
    );

    const { total } = result.data;
    const { data, columns } = result.data.dataResult;
    
    yield put(filterSHaddBluk(filter));
    yield put(shDataBulk(data));
    yield put(shColumnBulk(columns));
    yield put(shTotal(total));
    yield put(shPage(pageNumber));
    yield put(hide("getSHOverview"));
  } catch (err) {
    yield put(shDataBulk([]));
    yield put(shTotal(0));
    yield put(shPage(1));
    yield put(hide("getSHOverview"));
  }
}

export function* watchGetSHOverview() {
  yield takeLatest(FETCH_SH_OVERVIEW, getSHOverview);
}

function* shOverviewExcel(action) {
  try {
    const { testID, testName } = action;
    const response = yield call(getSHOverviewExcelApi, testID);
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
export function* watchSHOverviewExcel() {
  yield takeLatest("REQUEST_SH_OVERVIEW_EXCEL", shOverviewExcel);
}
