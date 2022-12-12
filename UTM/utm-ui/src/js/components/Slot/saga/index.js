import { call, takeLatest, put } from "redux-saga/effects";
import { getSlotListApi, postLinkSlotTestApi } from "../api/index";
import { slotAdd } from "../../../containers/Home/actions/index";
import {
  notificationMsg,
  notificationSuccess,
  notificationSuccessTimer
} from "../../../saga/notificationSagas";

function* getSlotList({ testID, slotID }) {
  if (testID === null) {
    return null;
  }

  try {
    // yield put({ type: 'LOADER_SHOW' });
    const result = yield call(getSlotListApi, testID);
    yield put(slotAdd(result.data, slotID));
  } catch (err) {
    console.log(err);
  }
  return null;
}
export function* watchGetSlotList() {
  yield takeLatest("FETCH_SLOT", getSlotList);
}

function* postLinkSlotTest(action) {
  try {
    // yield put({ type: 'LOADER_SHOW' });
    const result = yield call(postLinkSlotTestApi, action);

    const { data } = result;
    /**
     * TODO :: fetch data again
     * both Assign marker and Plate Filling page
     */
    yield put({
      type: "ROOT_SLOTID",
      slotID: action.slotID * 1,
      testID: data.testID,
    });
    yield put({
      type: "ROOT_STATUS",
      statusCode: data.statusCode,
      testID: data.testID,
    });

    const msg =
      action.slotID === ""
        ? "SLot was successfull Unassigned."
        : "Slot was successfully assigned.";
    yield put(notificationSuccessTimer(msg));
  } catch (e) {
    // yield put({ type: 'LOADER_HIDE' });
    yield put(notificationMsg(e.response.data));
  }
}
export function* watchPostLinkSlotTest() {
  yield takeLatest("UPDATE_SLOT_TEST_LINK", postLinkSlotTest);
}
