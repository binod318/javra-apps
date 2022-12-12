import { call, put, takeLatest, select, takeEvery } from "redux-saga/effects";
import {
  breederApi,
  cropChangeApi,
  breederReserveApi,
  periodApi,
  getAvailableSampleApi,
  slotDeleteApi,
  postSlotEditApi,
  leafDiskFetchSlotApi,
  leafDiskExportCapacityPlanningApi
} from "../api";

import {
  periodAdd,
  displayPeriodAdd,
  displayPeriodExpected,
  breedingFomrData,
  breedingMessage,
  breedingSubmit,
  breedingForced,
  breedingReset,
  breedingMaterialType,
  breederUpdate,
  breederUpdateForced,
  breederSlotFetch
} from "../action";
import {
  noInternet,
  notificationMsg,
  notificationSuccessTimer
} from "../../../saga/notificationSagas";
import { show, hide } from "../../../helpers/helper";

function* fetchSlot(action) {
  try {
    yield put(show("fetchSlot"));

    const { cropCode, brStationCode, pageNumber, pageSize, filter } = action;
    const result = yield call(
      leafDiskFetchSlotApi,
      cropCode,
      brStationCode,
      pageNumber,
      pageSize,
      filter
    );

    yield put({ type: "LEAF_DISK_FILTER_BREEDER_ADD_BLUK", filter });
    yield put({ type: "LEAF_DISK_BREEDER_SLOT", data: result.data.data });

    // yield put({ type: "BREEDER_SLOT_TOTAL", total: result.data.total });
    // yield put({ type: "BREEDER_SLOT_PAGE", pageNumber });
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
export function* watchLeafDiskFetchSlot() {
  yield takeEvery("LEAF_DISK_FETCH_BREEDER_SLOT", fetchSlot);
}

function getBreederPageSize(store) {
  return store.slotBreeder.total.pageSize || 200;
}

function* breeder() {
  try {
    yield put(show("breeder"));

    const result = yield call(breederApi);

    yield put(breedingFomrData(result.data));
    yield put(hide("breeder"));
  } catch (e) {
    yield put(hide("breeder"));
  }
}

export function* watchLeafDiskCapacityPlanning() {
  yield takeLatest("LEAF_DISK_CAPACITY_PLANNING_FETCH", breeder);
}

function* cropChange(action) {
  try {
    yield put(show("cropChange"));

    const result = yield call(cropChangeApi, action);
    if (result.status === 200) yield put(breedingMaterialType(result.data));
    yield put(hide("cropChange"));
  } catch (e) {
    yield put(hide("cropChange"));
    if (e.response !== undefined) {
      if (e.response.data) {
        const { data } = e.response;
        yield put(notificationMsg(data));
      }
    } else {
      yield put(noInternet);
    }
  }
}

export function* watchLeafDiskCapacityPlanningCropChange() {
  yield takeLatest(
    "LEAF_DISK_CAPACITY_PLANNING_FETCH_MATERIALTYPE",
    cropChange
  );
}

function* breederReserve(action) {
  try {
    yield put(show("breederReserve"));

    // breedingStationCode, cropCode
    const result = yield call(breederReserveApi, action);
    const { success, message } = result.data;

    if (success) {
      const state = yield select();
      const pageSize = getBreederPageSize(state);
      // Refetch table data after success
      const { breedingStationCode: brStationCode, cropCode } = action;
      yield put(breederSlotFetch(cropCode, brStationCode, 1, pageSize, []));

      yield put(breedingMessage(""));
      yield put(breedingSubmit(true));
      yield put(breedingForced(false));

      yield put(notificationSuccessTimer(message));
      yield put(breedingReset());
    } else {
      yield put(breedingMessage(message));
      yield put(breedingSubmit(false));
      yield put(breedingForced(true));
    }
    yield put(hide("breederReserve"));
  } catch (e) {
    yield put(hide("breederReserve"));
    if (e.response !== undefined) {
      if (e.response.data) {
        const { data } = e.response;
        yield put(notificationMsg(data));
      }
    } else {
      yield put(noInternet);
    }
  }
}

export function* watchLeafDiskCapacityPlanningReserve() {
  yield takeLatest("LEAF_DISK_CAPACITY_PLANNING_RESERVE", breederReserve);
}

function* period(action) {
  try {
    const result = yield call(periodApi, action);
    const { displayPeriod } = result.data;
    if (action.period === 1) {
      yield put(displayPeriodAdd(displayPeriod));
    } else {
      yield put(displayPeriodExpected(displayPeriod));
    }
  } catch (e) {
    console.log(e);
  }
}

export function* watchLeafDiskCapacityPlanningPeriod() {
  yield takeLatest("LEAF_DISK_CAPACITY_PLANNING_PERIOD_FETCH", period);
}

function* getAvailableSample(action) {
  try {
    const result = yield call(getAvailableSampleApi, action);
    if (result.status === 200) {
      const {
        availSample,
        displayPlannedWeek
      } = result.data;

      const obj = {
        planned: displayPlannedWeek,
        availTests: availSample
      };

      yield put(periodAdd(obj));
    }
  } catch (e) {
    console.log(e);
  }
}
export function* watchLeafDiskCapacityPlanningAvailableSample() {
  yield takeLatest(
    "LEAF_DISK_CAPACITY_PLANNING_AVAIL_SAMPLE_FETCH",
    getAvailableSample
  );
}

function* leafDiskSlotDelete(action) {
  try {
    yield put(show("slotDelete"));
    const { slotID, cropCode, brStationCode, slotName } = action;
    const result = yield call(slotDeleteApi, slotID);
    if (result.data) {
      // delete success fetch again and reirect to page 1
      const state = yield select();
      const pageSize = getBreederPageSize(state);
      yield put(breederSlotFetch(cropCode, brStationCode, 1, pageSize, []));
      yield put(
        notificationSuccessTimer(`Slot ${slotName} deleted successfully.`)
      );
    }

    yield put(hide("slotDelete"));
  } catch (e) {
    yield put(hide("slotDelete"));
    if (e.response !== undefined) {
      if (e.response.data) {
        const { data } = e.response;
        yield put(notificationMsg(data));
      }
    } else {
      yield put(noInternet);
    }
  }
}

export function* watchLeafDiskCapacityPlanningSlotDelete() {
  yield takeLatest("LEAF_DISK_SLOT_DELETE", leafDiskSlotDelete);
}

function* slotEdit(action) {
  try {
    yield put(show("slotEdit"));

    const result = yield call(postSlotEditApi, action);
    const { success, message } = result.data;

    if (success) {
      const state = yield select();
      const pageSize = getBreederPageSize(state);
      // Refetch table data after success
      const { brStationCode, cropCode } = action;
      yield put(breederSlotFetch(cropCode, brStationCode, 1, pageSize, []));
      yield put(breedingMessage(""));
      yield put(breederUpdate(false));
      yield put(breederUpdateForced(false));
    } else {
      yield put(breedingMessage(message));
      yield put(breederUpdate(true));
      yield put(breederUpdateForced(true));
    }
    yield put(hide("slotEdit"));
  } catch (e) {
    yield put(hide("slotEdit"));
    if (e.response !== undefined) {
      if (e.response.data) {
        const { data } = e.response;
        yield put(notificationMsg(data));
      }
    } else {
      yield put(noInternet);
    }
  }
}
export function* watchLeafDiskCapacityPlanningSlotEdit() {
  yield takeLatest("LEAF_DISK_CAPACITY_PLANNING_SLOT_EDIT", slotEdit);
}


function* leafDiskExportCapacityPlanning({ payload }) {
  try {
    yield put(show("leafDiskExportCapacityPlanning"));

    // const { testID, row } = action;
    const response = yield call(leafDiskExportCapacityPlanningApi, payload);
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

    yield put(hide("leafDiskExportCapacityPlanning"));
  } catch (e) {
    yield put(hide("leafDiskExportCapacityPlanning"));

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

export function* watchExportCapacityPlanningLeafDisk() {
  yield takeEvery("LEAF_DISK_EXPORT_CAPACITY_PLANNING", leafDiskExportCapacityPlanning);
}

