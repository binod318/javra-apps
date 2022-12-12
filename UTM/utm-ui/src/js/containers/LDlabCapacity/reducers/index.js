import { combineReducers } from "redux";
import column from "./column";
import data from "./data";

const RDTlabCapacity = combineReducers({
  column,
  data
});
export default RDTlabCapacity;
