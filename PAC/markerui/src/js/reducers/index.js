import { combineReducers } from "redux";

import sidemenuReducer from "../components/Aside/reducer";
import loader from "../components/Loader/reducer";
import notification from "../components/Notification/reducer";

import user from "./user";

// lab
import lab from "../containers/LabCapacity/labReducer";

// lab preparation
import labPreparation from "../containers/LabPreparation/labPreparationReducer";

// capacity
import capacity from "../containers/CapacitySO/capacitySOReducer";
import planning from "../containers/PlanningBatchesSO/planningBatchesSOReducer";

// marker per variety
import markerPerVariety from "../containers/MarkerPerVariety/markerPerVarietyReducer";

// criteria per crop
import criteriaPerCrop from "../containers/CriteriaPerCrop/criteriaPerCropReducer";

// lab results
import labResults from "../containers/LabResult/labResultReducer";

// total PAC
import totalPAC from "../containers/TotalPAC/TotalPACReducer";

const rootReducer = combineReducers({
  loader,
  notification,
  sidemenuReducer,
  user,

  totalPAC,

  lab,
  labPreparation,

  capacity,
  planning,

  markerPerVariety,
  criteriaPerCrop,

  labResults,
});
export default rootReducer;
