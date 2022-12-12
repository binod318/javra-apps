import { call, put } from "redux-saga/effects";

import {
  labResultfetchAPI,
  labResultPeriodAPI,
  determinationAssignmentsAPI,
  determinationAssignmentsDecisionDetailAPI,
  approvalDetAssignmentAPI,
  reTestDetAssignmentAPI,
  saveRemarksAPI,
  savePatternRemarksAPI,
  labPlatePositionFetchAPI
} from "./labResultApi";

import {
  labResultfetchActionCreator,
  labResutDeterminationAss,
  saveRemarksSucceeded,
  savePatternRemarksSucceeded,
  approveRetestSucceeded
} from "./labResultAction";

import {
  noInternet,
  notificationSuccess,
  notificationSuccessTimer,
  notificationMsg,
} from "../../saga/notificationSagas";
import { show, hide } from "../../helpers/helper";

export function* labResultFetch(action) {
  try {
    yield put(show("labResultfetch"));

    const result = yield call(labResultfetchAPI, action);
    const {
      status,
      data: { Data, Total },
    } = result;

    if (status === 200) {
      const { Data: Details, Columns } = Data;

      if (Details.length === 0) {
        yield put(hide("labResultfetch"));
        yield put({
          type: "LAB_RESULT_DATA_ADD",
          data: [],
        });
      } else {
        yield put({
          type: "LAB_RESULT_DATA_ADD",
          data: Details,
        });
      }

      yield put({
        type: "LABRESULT_TOTAL",
        total: Total,
      });
      const keyValue = {
        DetAssignmentID: "Det. Ass#",
        SampleNr: "Sample#",
        BatchNr: "Batch#",
        Folder: "Folder#",
      };

      const newCol = [];
      Columns.map((c, i) => {
        const editable = false;
        const IsVisible = false;
        newCol.push({
          ColumnID: c.ColumnID,
          Editable: editable, // ? true : false,
          IsVisible: !IsVisible,
          Label: c.ColumnLabel,
          order: newCol.length,
        });
        if (i === Columns.length - 1) {
          newCol.push({
            ColumnID: "Action",
            Editable: editable, // ? true : false,
            IsVisible: true,
            Label: "Action",
            order: newCol.length,
          });
        }
      });
      yield put({
        type: "LAB_RESULT_COLUMN_ADD",
        data: newCol,
      });
    }

    yield put(hide("labResultfetch"));
  } catch (e) {
    yield put(hide("labResultfetch"));
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}

export function* labResultPeriodFetch(action) {
  try {
    yield put(show("labResultPeriodFetch"));

    const result = yield call(labResultPeriodAPI, action.year);
    const { Data, Errors, Message } = result.data;

    if (Errors.length) {
      yield put(noInternet);
    } else {
      yield put({
        type: "LAB_RESULT_PERIOD_ADD",
        data: Data,
      });
      const periodDate = Data.find((y) => y.Current) || Data[0];
      yield put({
        type: "LAB_RESULT_PERIOD_SELECT",
        selected: periodDate.PeriodID,
      });
    }

    yield put(hide("labResultPeriodFetch"));
  } catch (e) {
    yield put(hide("labResultPeriodFetch"));
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

export function* determinationAssignmentsFetch(action) {
  try {
    yield put(show("determinationAssignmentsFetch"));

    const result = yield call(determinationAssignmentsAPI, action.id);
    const { status, data } = result;
    if (status === 200) {
      const {
        DetAssignmentInfo,
        ResultInfo,
        TestInfo,
        ValidationInfo,

        VarietyInfoColumn,
        VarietyInfoData,
      } = data;

      const columns = [];

      VarietyInfoColumn.forEach((c, i) => {
        const editable = false;
        const IsVisible = false;

        columns.push({
          ColumnID: c.ColumnID,
          Editable: editable, // ? true : false,
          IsVisible: !IsVisible,
          Label: c.ColumnLabel, // keyValue[c] ||
          order: columns.length,
          isExtraTraitMarker: c.IsExtraTraitMarker,
        });
      });

      yield put({
        type: "LAB_RESULT_DETAIL_COLUMN_ADD",
        data: columns,
      });
      yield put({
        type: "LAB_RESULT_DETAIL_DATA_ADD",
        data: VarietyInfoData,
      });
      yield put({
        type: "LAB_RESULT_VALIDATION_ADD",
        data: ValidationInfo[0],
      });
      yield put({
        type: "LAB_RESULT_TESTINFO_ADD",
        data: TestInfo[0],
      });
      yield put({
        type: "LAB_RESULT_RESULTIFNO_ADD",
        data: ResultInfo[0],
      });
      yield put({
        type: "LAB_RESULT_DETASSOGM<EMTOMFP_ADD",
        data: DetAssignmentInfo[0],
      });
    }

    yield put(hide("determinationAssignmentsFetch"));
  } catch (e) {
    yield put(hide("determinationAssignmentsFetch"));
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

export function* determinationAssignmentsDetailFetch(action) {
  try {
    yield put(show("determinationAssignmentsDetailFetch"));

    const result = yield call(
      determinationAssignmentsDecisionDetailAPI,
      action
    );
    const { status, data } = result;
    if (status === 200) {
      const { Detail, Columns } = data;
      yield put({
        type: "LAB_RESULT_DETAIL2_DATA_ADD",
        data: Detail,
      });

      const cols = [];
      Columns.map((c) => {
        cols.push({
          ColumnID: c.ColumnID,
          Editable: c.Editable, // ? true : false,
          IsVisible: true,
          Label: c.ColumnLabel, // keyValue[c] ||
          order: c.DisplayOrder,
          sort: c.Sort
        });
      });
      yield put({
        type: "LAB_RESULT_DETAIL2_COLUMN_ADD",
        data: cols,
      });
    }

    yield put(hide("determinationAssignmentsDetailFetch"));
  } catch (e) {
    yield put(hide("determinationAssignmentsDetailFetch"));
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

export function* approvalDetAssignment(action) {
  try {
    yield put(show("approvalDetAssignment"));

    const result = yield call(approvalDetAssignmentAPI, action.id);
    const { data, status } = result;
    if (data && status === 200) {
      yield put(notificationSuccessTimer("Successfully approved."));
      yield put(labResutDeterminationAss(action.id));
      yield put(approveRetestSucceeded());
    }

    yield put(hide("approvalDetAssignment"));
  } catch (e) {
    yield put(hide("approvalDetAssignment"));
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

export function* reTestDetAssignment(action) {
  try {
    yield put(show("reTestDetAssignment"));

    const result = yield call(reTestDetAssignmentAPI, action.id);
    const { data, status } = result;
    if (data && status === 200) {
      yield put(notificationSuccessTimer("Successfully updated to Retest."));
      yield put(labResutDeterminationAss(action.id));
      yield put(approveRetestSucceeded());
    }

    yield put(hide("reTestDetAssignment"));
  } catch (e) {
    yield put(hide("reTestDetAssignment"));
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

export function* saveRemarks(action) {
  try {
    yield put(show("saveRemarks"));
    const result = yield call(saveRemarksAPI, action.payload);
    yield put(hide("saveRemarks"));
    if (result.data === true) {
      yield put(saveRemarksSucceeded(action.payload.Remarks));
    } else throw result;
  } catch (error) {
    yield put(hide("saveRemarks"));
    if (error.data && error.data.errorType) {
      if (error.data.errorType === 2) {
        const {
          errorType: ErrorType,
          code: Code,
          message: Message,
        } = error.data;
        yield put(notificationMsg({ ErrorType, Code, Message }));
      } else yield put(noInternet);
    } else {
      yield put(noInternet);
    }
  }
}

export function* savePatternRemarks(action) {
  try {
    console.log(action);
    yield put(show("savePatternRemarks"));
    const result = yield call(savePatternRemarksAPI, action.payload);
    yield put(hide("savePatternRemarks"));
    if (result.data === true) {
      yield put(savePatternRemarksSucceeded(action.payload.Remarks));
    } else throw result;
  } catch (error) {
    yield put(hide("savePatternRemarks"));
    if (error.data && error.data.errorType) {
      if (error.data.errorType === 2) {
        const {
          errorType: ErrorType,
          code: Code,
          message: Message,
        } = error.data;
        yield put(notificationMsg({ ErrorType, Code, Message }));
      } else yield put(noInternet);
    } else {
      yield put(noInternet);
    }
  }
}

export function* labPlatePositionFetch(action) {
  try {
    yield put(show("labPlatePositionFetch"));
    const { patternID } = action;
    const result = yield call(labPlatePositionFetchAPI, patternID);

    const { data } = result;
    const { Detail, Columns } = data;
    yield put(hide("labPlatePositionFetch"));
    yield put({
      type: "PLATE_POSITION_ADD",
      data: { patternID, data: Detail, columns: Columns },
    });

    yield put(hide("labPlatePositionFetch"));
  } catch (e) {
    yield put(hide("labPlatePositionFetch"));
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}

