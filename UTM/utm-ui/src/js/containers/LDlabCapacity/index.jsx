import { connect } from "react-redux";

import LDlabComponent from "./components/LDlabComponent";
import "./LDlabCapacity.scss";
import {
  labFetch,
  labDataChange,
  labDataRowChange,
  labDataUpdate
} from "./action";

import { locationFetch } from "../../action"
import { setPageTitle, sidemenuClose } from "../../action";

const mapState = state => ({ 
  data: state.ldLabCapacity.data,
  location: state.location 
});

const mapDispatch = dispatch => ({
  pageTitle: () => dispatch(setPageTitle("LD Lab Capacity")),
  sidemenu: () => dispatch(sidemenuClose()),
  labFetch: (year, siteLocation) => dispatch(labFetch(year, siteLocation)),
  locationFetch: () => dispatch(locationFetch()),
  labDataChange: (index, key, value) =>
    dispatch(labDataChange(index, key, value)),
  labDataRowChange: (key, value) => dispatch(labDataRowChange(key, value)),
  labDataUpdate: (siteLocation, data, year) => dispatch(labDataUpdate(siteLocation, data, year))
});

export default connect(
  mapState,
  mapDispatch
)(LDlabComponent);
