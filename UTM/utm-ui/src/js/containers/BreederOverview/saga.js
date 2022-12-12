import { call, put, takeEvery } from "redux-saga/effects";
import { noInternet, notificationMsg } from "../../saga/notificationSagas";
// notificationSuccess
import { fetchSlotAPi, exportCapacityPlanningApi } from "./api";
import { show, hide } from "../../helpers/helper";

function* fetchSlot(action) {
  try {
    yield put(show("fetchSlot"));

    const { cropCode, brStationCode, pageNumber, pageSize, filter } = action;
    const result = yield call(
      fetchSlotAPi,
      cropCode,
      brStationCode,
      pageNumber,
      pageSize,
      filter
    );

    yield put({ type: "FILTER_BREEDER_ADD_BLUK", filter });
    yield put({ type: "BREEDER_SLOT", data: result.data.data });

    yield put({ type: "BREEDER_SLOT_TOTAL", total: result.data.total });
    yield put({ type: "BREEDER_SLOT_PAGE", pageNumber });
    yield put(hide("fetchSlot"));
  } catch (e) {
    yield put(hide("fetchSlot"));
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}
export function* watchFetchSlot() {
  yield takeEvery("FETCH_BREEDER_SLOT", fetchSlot);
}

function* exportCapacityPlanning({ payload }) {
  try {
    yield put(show("exportCapacityPlanning"));

    // const { testID, row } = action;
    const response = yield call(exportCapacityPlanningApi, payload);
    if (response.status === 200) {
      const fileName = `${payload.cropCode}-${payload.brStationCode}-${
        new Date().toJSON().split("T")[0]
      }`;
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement("a");
      link.href = url;
      const fn = fileName;
      // link.setAttribute('download', `C&T_Markers_${fn}.xlsx`);
      link.setAttribute("download", `${fn}.xlsx`);
      document.body.appendChild(link);
      link.click();
    }

    yield put(hide("exportCapacityPlanning"));
  } catch (e) {
    yield put(hide("exportCapacityPlanning"));

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

export function* watchExportCapacityPlanning() {
  yield takeEvery("EXPORT_CAPACITY_PLANNING", exportCapacityPlanning);
}
