import { call, put, select } from "redux-saga/effects";

import {
  getCriteriaPerCropAPI,
  postCriteriaPerCropAPI,
} from "./criteriaPerCropApi";

import {
  criteriaPerCropFetch,
  criteriaPerCropColumnAdd,
  criteriaPerCropDataAdd,
  criteriaPerCropCropsAdd,
  criteriaPerCropMaterialTypesAdd,
  criteriaPerCropTotal,
} from "./criteriaPerCropAction";

import {
  noInternet,
  notificationMsg,
  notificationTimer,
  notificationSuccess
} from "../../saga/notificationSagas";
import { show, hide } from "../../helpers/helper";

export function* getCriteriaPerCrop(action) {
  try {
    yield put(show("getCriteriaPerCrop"));
    const { page, size, sortBy, sortOrder, filter } = action;

    const result = yield call(
      getCriteriaPerCropAPI,
      page,
      size,
      sortBy,
      sortOrder,
      filter
    );
    const { Data: D, Errors, Message, Total } = result.data;

    if (Errors.length) {
      yield put(noInternet);
    } else {
      const cols = [];
      const emptyObj = {};

      const { Data, Columns, Crops, MaterialTypes } = D;

      Columns.map((c, i) => {
        const { ColumnID, ColumnLabel: Label, IsVisible } = c;
        const editable = false;

        cols.push({
          ColumnID,
          Editable: editable, // ? true : false,
          IsVisible,
          Label,
          order: cols.length,
          sort: false,
          filter: false,
          filtered: true,
          filteredValue: () => {},
        });
        if (i === Columns.length - 1) {
          cols.push({
            ColumnID: "Action",
            Editable: editable, // ? true : false,
            IsVisible: true,
            Label: "Action",
            order: 100,
          });
        }
      });

      // Condition if data is empty
      if (Data.length === 0) {
        yield put(criteriaPerCropDataAdd([]));
        yield put(criteriaPerCropColumnAdd(cols));
        yield put(criteriaPerCropCropsAdd(Crops));
        yield put(criteriaPerCropMaterialTypesAdd(MaterialTypes));
        yield put(hide("getCriteriaPerCrop"));
        yield put(criteriaPerCropTotal(1));
        return null;
      }

      yield put(criteriaPerCropColumnAdd(cols));
      yield put(criteriaPerCropDataAdd(Data));
      yield put(criteriaPerCropCropsAdd(Crops));
      yield put(criteriaPerCropMaterialTypesAdd(MaterialTypes));
      yield put(criteriaPerCropTotal(Total));

    }
    yield put(hide("getCriteriaPerCrop"));
  } catch (e) {
    yield put(hide("getCriteriaPerCrop"));
    if (e.response !== undefined) {
      if (e.response.data) {
        const {
          errorType: ErrorType,
          code: Code,
          message: Message,
        } = e.response.data;
        if (ErrorType === 1) {
          yield put(noInternet);
          return null;
        }
        yield put(notificationMsg({ ErrorType, Code, Message }));
      }
    } else {
      yield put(noInternet);
    }
  }
}

export function* postCriteriaPerCrop(payload) {
  console.log('payload', payload);
  try {
    const {
      CropCode,
      MaterialTypeID,
      ThresholdA,
      ThresholdB,
      CalcExternalAppHybrid,
      CalcExternalAppParent,
      action
    } = payload;

    const result = yield call(
      postCriteriaPerCropAPI,
      CropCode,
      MaterialTypeID,
      ThresholdA,
      ThresholdB,
      CalcExternalAppHybrid,
      CalcExternalAppParent,
      action
    );

    const { Errors, Message } = result.data;

    const state = yield select();
    const { page, pageSize, sorter, filter } = state.criteriaPerCrop;

    if (Errors.length) {
      yield put(noInternet);
    } else {
      yield put(notificationSuccess(Message));
      yield put(criteriaPerCropFetch(page, pageSize, sorter.sortBy, sorter.sortOrder, filter));
    }
  } catch (e) {
    if (e.response !== undefined) {
      if (e.response.data) {
        const {
          errorType: ErrorType,
          code: Code,
          message: Message,
        } = e.response.data;
        if (ErrorType === 1) {
          yield put(noInternet);
          return null;
        }
        yield put(notificationMsg({ ErrorType, Code, Message }));
      }
    } else {
      yield put(noInternet);
    }
  }
}
