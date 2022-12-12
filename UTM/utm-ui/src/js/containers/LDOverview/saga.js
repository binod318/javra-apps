import { call, takeLatest, put } from "redux-saga/effects";

import { getLDtestOverviewApi, getLDoverviewExcelApi } from "./api";
import { FETCH_LD_OVERVIEW } from "./constant";
import { ldTotal, ldPage, ldDataBulk, ldColumnBulk, filterLDaddBluk } from "./action";
import { show, hide } from "../../helpers/helper";

function* getLDOverview(action) {
  try {
    yield put(show("getLDOverview"));
    const { pageNumber, pageSize, filter, active } = action;

    const result = yield call(
      getLDtestOverviewApi,
      pageNumber,
      pageSize,
      filter,
      active
    );

    const { total } = result.data;
    const { data, columns } = result.data.dataResult;
    yield put(filterLDaddBluk(filter));
    yield put(ldDataBulk(data));
    yield put(ldColumnBulk(columns));
    yield put(ldTotal(total));
    yield put(ldPage(pageNumber));
    yield put(hide("getLDOverview"));
  } catch (err) {
    yield put(ldDataBulk([]));
    yield put(ldTotal(0));
    yield put(ldPage(1));
    yield put(hide("getLDOverview"));
  }
}

export function* watchGetLDOverview() {
  yield takeLatest(FETCH_LD_OVERVIEW, getLDOverview);
}

function* ldOverviewExcel(action) {
  try {
    const { testID, testName } = action;
    const response = yield call(getLDoverviewExcelApi, testID);
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
export function* watchLDOverviewExcel() {
  yield takeLatest("REQUEST_LD_OVERVIEW_EXCEL", ldOverviewExcel);
}
