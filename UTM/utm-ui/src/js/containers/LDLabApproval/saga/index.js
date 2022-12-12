import { call, takeLatest, takeEvery, put } from "redux-saga/effects";
import {
  getLDApprovalListApi,
  getLDPlanPeriodsApi,
  approveLDSlotApi,
  denyLDSlotApi,
  updateLDSlotPeriodApi
} from "../api";
import { getLDApprovalListDone, getLDPlanPeriodsDone } from "../actions";
import {
  noInternet,
  notificationMsg,
  notificationSuccess,
  notificationSuccessTimer
} from "../../../saga/notificationSagas";
import { show, hide } from "../../../helpers/helper";

function* getLDApprovalList({ periodID, siteID }) {
  try {
    yield put(show("getLDApprovalList"));
    const result = yield call(getLDApprovalListApi, periodID, siteID);
    yield put(getLDApprovalListDone(result.data));
    yield put(hide("getLDApprovalList"));
  } catch (e) {
    yield put(hide("getLDApprovalList"));
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
export function* watchGetLDApprovalList() {
  yield takeEvery("GET_LD_APPROVAL_LIST", getLDApprovalList);
}

function* getLDPlanPeriods() {
  try {
    yield put(show("getLDPlanPeriods"));

    const result = yield call(getLDPlanPeriodsApi);
    yield put(getLDPlanPeriodsDone(result.data));
    yield put(hide("getLDPlanPeriods"));
  } catch (e) {
    yield put(hide("getLDPlanPeriods"));
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
export function* watchGetLDPlanPeriods() {
  yield takeLatest("GET_LD_PLAN_PERIODS", getLDPlanPeriods);
}

function* ldApproveSlot({ slotID, selectedPeriodID, siteID, forced }) {
  try {
    yield put(show("ldApproveSlot"));

    const result = yield call(approveLDSlotApi, slotID, forced);

    const { success, message } = result.data;
    if (success) {
      yield put(notificationSuccessTimer(message));
      const ldApprovalList = yield call(getLDApprovalListApi, selectedPeriodID, siteID);
      yield put(getLDApprovalListDone(ldApprovalList.data));
    }
    yield put(hide("ldApproveSlot"));
  } catch (e) {
    yield put(hide("ldApproveSlot"));
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
export function* watchLDSlotApproval() {
  yield takeLatest("LD_APPROVE_SLOT", ldApproveSlot);
}

function* ldDenySlot({ slotID, selectedPeriodID, siteID }) {
  try {
    yield put(show("ldDenySlot"));

    const result = yield call(denyLDSlotApi, slotID);
    const { success, message } = result.data;
    if (success) {
      yield put(notificationSuccess(message));
      const ldApprovalList = yield call(getLDApprovalListApi, selectedPeriodID, siteID);
      yield put(getLDApprovalListDone(ldApprovalList.data));
    }
    yield put(hide("ldDenySlot"));
  } catch (e) {
    yield put(hide("ldDenySlot"));
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
export function* watchLDSlotDenial() {
  yield takeLatest("LD_DENY_SLOT", ldDenySlot);
}

function* updateLDSlotPeriod({ slotID, periodID, siteID, plannedDate }) {
  try {
    yield put(show("updateLDSlotPeriod"));

    const result = yield call(
      updateLDSlotPeriodApi,
      slotID,
      plannedDate
    );
    const { success, message } = result.data;
    if (success) {
      yield put(notificationSuccess(message));
      const ldApprovalList = yield call(getLDApprovalListApi, periodID, siteID);
      yield put(getLDApprovalListDone(ldApprovalList.data));
    }
    yield put(hide("updateLDSlotPeriod"));
  } catch (e) {
    yield put(hide("updateLDSlotPeriod"));
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
export function* watchUpdateLDSlotPeriod() {
  yield takeLatest("UPDATE_LD_SLOT_PERIOD", updateLDSlotPeriod);
}
