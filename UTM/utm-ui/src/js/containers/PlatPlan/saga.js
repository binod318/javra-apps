import { call, takeLatest, put } from "redux-saga/effects";

import { getPlatPlanApi, postPlatPlanExcelApi } from "./api";
import {
  FETCH_PLAT_PLAN,
  PLAT_PLAN_BULK,
  PLAT_PLAN_RECORDS,
  PLAT_PLAN_PAGE,
  PLAT_PLAN_EXPORT
} from "./constant";
import { filterPlatPlanAddBluk, platPlanExport } from "./action";
// storeCrops,
import { show, hide } from "../../helpers/helper";

function* getPlatPlan(action) {
  try {
    yield put(show("getPlatePlan"));
    const { pageNumber, pageSize, filter, active, btr } = action;

    const result = yield call(
      getPlatPlanApi,
      pageNumber,
      pageSize,
      filter,
      active,
      btr
    );

    const { total, data } = result.data;

    yield put(filterPlatPlanAddBluk(filter));
    yield put({ type: PLAT_PLAN_BULK, data });
    yield put({ type: PLAT_PLAN_RECORDS, total });
    yield put({ type: PLAT_PLAN_PAGE, pageNumber });
    yield put(hide("getPlatePlan"));
  } catch (e) {
    yield put(hide("getPlatePlan"));
    /**
     * I am getting this error
     * @type {[type]}
     * data: {errorType: 1, code: "1218375", message: "There is no row at position 0."}
     * so i am just empthing data
     */
    yield put({ type: PLAT_PLAN_BULK, data: [] });
    yield put({ type: PLAT_PLAN_RECORDS, total: 0 });
    yield put({ type: PLAT_PLAN_PAGE, pageNumber: 1 });
  }
}
export function* watchGetPlatPlan() {
  yield takeLatest(FETCH_PLAT_PLAN, getPlatPlan);
}

function* postPlatPlanExport(action) {
  try {
    yield put(show("postPlatPlanExport"));

    const { testID, row, controlPosition } = action;
    const response = yield call(postPlatPlanExcelApi, testID, controlPosition);
    if (response.status === 200) {
      const fileName = row.platePlan || row.test || "newTest";
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement("a");
      link.href = url;
      const fn = fileName || action.testID;
      // link.setAttribute('download', `C&T_Markers_${fn}.xlsx`);
      link.setAttribute("download", `${fn}.xlsx`);
      document.body.appendChild(link);
      link.click();
    }

    yield put(hide("postPlatPlanExport"));
  } catch (e) {
    yield put(hide("postPlatPlanExport"));
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
export function* watchPostPlatPlanExport() {
  yield takeLatest(PLAT_PLAN_EXPORT, postPlatPlanExport);
}
