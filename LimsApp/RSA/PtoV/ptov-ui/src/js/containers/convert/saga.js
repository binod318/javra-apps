import { call, put, takeLatest, select } from "redux-saga/effects"; // select
import { getmappedgermplasmApi, postUnmapColumns } from "./api";
import {
  convertProcessing,
  convertSuccess,
  convertError,
  convertBluk,
  convertColumn,
  convertTotal,
  convertSize,
  convertPage,
  convertSort,
  unmapProcessing,
  unmapSuccess,
  unmapError
} from "./action";

function* convert(action) {
  try {
    yield put(convertProcessing());
    const { fileName, pageNumber, pageSize, filter, sorting } = action;

    const fileStatus = yield select(state => state.main.fileStatus);
    let newFilter = [];
    switch (fileStatus) {
      case 0: // all
        newFilter = [...filter];
        break;
      case 200:
        newFilter = [
          ...filter,
          {
            display: "status",
            name: "statusCode",
            value: 200,
            expression: "contains",
            operator: "or"
          },
          {
            display: "status",
            name: "statusCode",
            value: 250,
            expression: "contains",
            operator: "or"
          }
        ];
        break;
      default:
        // 100 & 300
        newFilter = [
          ...filter,
          {
            display: "status",
            name: "statusCode",
            value: fileStatus,
            expression: "contains",
            operator: "and"
          }
        ];
    }

    const response = yield call(
      getmappedgermplasmApi,
      fileName,
      pageNumber,
      pageSize,
      newFilter,
      sorting
    );

    const { success, errors, data, total } = response.data;

    if (!success) {
      yield put(convertBluk([]));
      yield put(convertColumn([]));
      yield put(convertTotal(0));
      yield put(convertError(errors));
    } else {
      yield put(convertBluk(data.data));
      yield put(convertColumn(data.columns));
      yield put(convertTotal(total));
      yield put(convertSize(pageSize));
      yield put(convertPage(pageNumber));
      yield put(convertSort(sorting.name, sorting.direction));
      yield put(convertSuccess());
    }
  } catch (e) {
    const { message } = e;
    yield put(convertError(message));
  }
}
export function* watchCovert() {
  yield takeLatest("FETCH_CONVERT", convert);
}

function* unmapColumn(action) {
  const cropCode = yield select(state => state.main.files);
  try {
    yield put(unmapProcessing());
    const { cropCode, columns } = action;

    const response = yield call(postUnmapColumns, cropCode, columns);
    if (response.data) {
      yield put({
        type: "CONVERT_COL_DELETION",
        columns
      });
      yield put(unmapSuccess(`Columns succesfully removed.`));
    } else {
      yield put(unmapError(`Columns not removed.`));
    }

    // FILTER_CONVERT_ADD
  } catch (e) {
    const { message } = e;
    yield put(unmapError(message));
  }
}
export function* watchUnmapColumn() {
  yield takeLatest("UNMAP_COLUMN", unmapColumn);
}
