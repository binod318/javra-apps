import { call, put, select } from "redux-saga/effects";

import {
  planningPeriodAPI,
  planningDeterminationAssignmentAPI,
  postDeterminationAssignmentsAutoPlanAPI,
  postDeterminationAssignmentsChangePlanAPI,
} from "./planningBatchesSOApi";
import {
  planningPeriodAdd,
  planningPeriodSelected,
  planningSetFillRateTotalUsed,
  planningSetFillRateTotalReserved
} from "./planningBatchesSOAction";

import {
  noInternet,
  notificationMsg,
  notificationSuccess,
  notificationAlert
} from "../../saga/notificationSagas";
import { show, hide } from "../../helpers/helper";

export function* planningSOPeriod(action) {
  try {
    yield put(show("planningSOPeriod"));

    const result = yield call(planningPeriodAPI, action.year);

    const { Data, Errors, Message } = result.data;

    if (Errors.length) {
      yield put(noInternet);
    } else {
      yield put({
        type: "PLANNING_PERIOD_ADD",
        data: Data,
      });
      const periodDate = Data.find((y) => y.Current) || Data[0];
      yield put({
        type: "PLANNING_PERIOD_SELECT",
        selected: periodDate.PeriodID,
      });

      yield put({
        type: "PLANNING_PERIOD_DATE",
        date: {
          StartDate: periodDate.StartDate,
          EndDate: periodDate.EndDate,
        },
      });
    }

    yield put(hide("planningSOPeriod"));
  } catch (e) {
    yield put(hide("planningSOPeriod"));
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

export function* planningDeterminationAssignment(action) {
  try {
    const { periodID, StartDate, EndDate, includeUnplanned } = action;
    if (!periodID || !StartDate || !EndDate) return;
    yield put(show("planningDeterminationAssignment"));

    const result = yield call(
      planningDeterminationAssignmentAPI,
      periodID,
      StartDate,
      EndDate,
      includeUnplanned
    );

    const { Data, Message} = result.data;
    const { Groups, Details, TotalUsed, TotalReserved } = Data

    yield put({ type: "PLANNING_DATA_ADD", data: [] });
    yield put({ type: "PLANNING_COLUMN_ADD", data: [] });
    yield put({ type: "GROUP_ADD", group: [] });
    yield put({ type: "PLANNING_DATA_CHANGE", change: [] });

    if (Details.length > 0 && !false) {
      const columns = [];
      const emptyObj = {};

      const keyValue = {
        IsLabPriority: "Lab Prio",
        DetAssignmentID: "Determination Ass.",
        MethodCode: "Method",
        ABSCropCode: "Crop ABS",
        SampleNr: "Sample",
        UtmostInlayDate: "Utmost Inlay",
        ExpectedReadyDate: "Expected Ready",
        PriorityCode: "Prio",
        BatchNr: "Batch",
        RepeatIndicator: "Repeat",
        Article: "Article",
        Process: "Process",
        ProductStatus: "Product Status",
        BatchOutputDesc: "Batch Output Description",
        IsPlanned: "Planned",
        PlannedDate: "Planned Date",
        Remarks: "Remarks",
      };
      const dataKeys = Object.keys(Details[0]);

      dataKeys.forEach((c) => {
        emptyObj[c] = "";
        const editable =
          c == "IsPlanned" || c == "RepeatIndicator" || c == "IsLabPriority";
        if (
          c == "UsedFor" ||
          c == "CropCode" ||
          c === "ABSCropCode" ||
          c === "MethodCode" ||
          c === "IsPacComplete" ||
          c === "VarietyNr" ||
          c === "CanEditPlanning" ||
          c === "NrOfPlates"
        ) {
        } else {
          columns.push({
            ColumnID: c,
            Editable: editable, // ? true : false,
            IsVisible: c !== "VarietyNr" ? true : false,
            Label: keyValue[c],
            order: columns.length,
          });
        }
      });

      yield put({
        type: "PLANNING_COLUMN_ADD",
        data: columns,
      });

      // new row item created
      const newArray = [];

      // group item count
      const groupItem = [];
      const group = Groups.map((g) => {
        const {
          ABSCropCode,
          MethodCode,
          UsedFor,
          NrOfResPlates,
          TotalPlates,
          SlotName,
        } = g;

        /**
         * note:
         * creating text for group header row
         */
        const text = `${ABSCropCode} (${MethodCode}), Slot: ${SlotName}, ${UsedFor} (Capacity: ${NrOfResPlates}/${TotalPlates})`;

        /**
         * note:
         * creating madeKey just to count items in grouns so we can exclude group having zero item
         */
        const madeKey = `${ABSCropCode}${MethodCode}${UsedFor}`;

        // default group count zero
        groupItem[madeKey] = 0;
        Details.forEach((m) => {
          if (
            m.ABSCropCode === ABSCropCode &&
            m.MethodCode === MethodCode &&
            m.UsedFor === UsedFor
          ) {
            // group item count increment by one
            groupItem[madeKey] = groupItem[madeKey] + 1;
          }
        });

        return {
          ...g,
          ...{
            items:
              groupItem[`${g.ABSCropCode}${g.MethodCode}${g.UsedFor}`] || 0,
          },
        };
      });

      const change = [];
      Details.forEach((detail) => {
        const {
          DetAssignmentID,
          IsPlanned: flag,
          CanEditPlanning: can,
          IsLabPriority: perioInit,
        } = detail;
        change.push({
          ...detail,
          DetAssignmentID,
          can,
          init: flag,
          flag,
          change: false,
          perioInit,
          perioChange: false,
        });
      });
      yield put({ type: "PLANNING_DATA_CHANGE", change });

      yield put({
        type: "PLANNING_DATA_ADD",
        data: Details, // backup date set in or condition
      });

      if (Groups.length > 0) {
        yield put({
          type: "GROUP_ADD",
          group,
        });
      }
    } else {
      yield put({
        type: "PLANNING_DATA_ADD",
        data: [],
      });
      yield put({
        type: "PLANNING_COLUMN_ADD",
        data: [],
      });
      yield put({
        type: "GROUP_ADD",
        group: [],
      });
    }

    //Store Fillrate info    
    yield put(planningSetFillRateTotalUsed(TotalUsed));
    yield put(planningSetFillRateTotalReserved(TotalReserved));

    //Display Big warning if Message from response is not empty
    if(Message != ''){
      const obj = {
        message: Message,
        type: 1
      }
      yield put(notificationAlert(obj));
    }

    yield put(hide("planningDeterminationAssignment"));
  } catch (e) {
    yield put(hide("planningDeterminationAssignment"));
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

export function* planningAutoplan(action) {
  try {
    const { periodID, StartDate, EndDate } = action;
    if (!periodID || !StartDate || !EndDate) return;
    yield put(show("planningDeterminationAssignment"));

    const result = yield call(
      postDeterminationAssignmentsAutoPlanAPI,
      periodID,
      StartDate,
      EndDate
    );
    if (result.status === 200) {
      yield put({
        type: "PLANNING_DETERMINATION_FETCH",
        periodID,
        StartDate,
        EndDate,
        includeUnplanned: false,
      });
    }
    yield put(hide("planningDeterminationAssignment"));
  } catch (e) {
    yield put(hide("planningDeterminationAssignment"));
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

export function* planningDeterminationConfirmPlan(action) {
  try {
    const { obj, periodID, startEndDate } = action;
    yield put(show("planningDeterminationConfirmPlan"));

    const result = yield call(
      postDeterminationAssignmentsChangePlanAPI,
      periodID,
      obj
    );
    const { Data, Errors, Message } = result.data;

    if (Errors.length) {
      yield put(
        notificationMsg({
          message: Errors.map((e) => e.Message) || "",
        })
      );
    } else {
      if (result.status === 200) {
        const { Message } = result.data;
        yield put(notificationSuccess(Message));

        const { StartDate, EndDate } = startEndDate;
        yield put({
          type: "PLANNING_DETERMINATION_FETCH",
          periodID,
          StartDate,
          EndDate,
          includeUnplanned: false,
        });
      }
    }
    yield put(hide("planningDeterminationConfirmPlan"));
  } catch (e) {
    yield put(hide("planningDeterminationConfirmPlan"));
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
