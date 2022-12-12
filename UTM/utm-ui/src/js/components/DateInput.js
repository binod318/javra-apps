import React from "react";
import PropTypes from "prop-types";
import moment from "moment";
import DatePicker from "react-datepicker";
import "react-datepicker/dist/react-datepicker.css";
import { isWeekday } from "../helpers/helper";

moment().locale("en");

const DateInput = props => (
  <div className="dateBox">
    <label>{props.label}</label> {/* eslint-disable-line */}
    <DatePicker
      id={props.id}
      name={props.name}
      disabled={props.disabled}
      selected={props.selected}
      minDate={props.todayDate}
      onChange={props.change}
      dateFormat={window.userContext.dateFormat}
      showWeekNumbers
      locale="en-gb"
      filterDate={isWeekday}
    />
    <i className="icon icon-calendar-inv" />
  </div>
);
// showWeekNumbers
DateInput.defaultProps = {
  id: "",
  disabled: null,
  name: ""
};
DateInput.propTypes = {
  selected: PropTypes.any, // eslint-disable-line
  id: PropTypes.string,
  name: PropTypes.string,
  label: PropTypes.string.isRequired,
  change: PropTypes.func.isRequired,
  disabled: PropTypes.bool,
  todayDate: PropTypes.object.isRequired // eslint-disable-line react/forbid-prop-types
};
export default DateInput;
