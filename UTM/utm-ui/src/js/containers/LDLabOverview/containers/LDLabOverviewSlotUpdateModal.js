/**
 * Created by sushanta on 3/27/18.
 */
import React from "react";
import moment from "moment";
import DatePicker from "react-datepicker";
import PropTypes from "prop-types";
import Wrapper from "../../../components/Wrapper/wrapper";
import { isWeekday } from "../../../helpers/helper";

class LabOverviewSlotUpdateModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      today: moment(),
      plannedPeriod: moment(props.plannedDate, window.userContext.dateFormat),
      samples: props.samples,
      updatePeriod: props.updatePeriod
    };
  }
  handlePlannedDateChange = date => {
    this.setState({
      plannedPeriod: date,
      expectedPeriod: moment(date).add(2, "weeks")
    });
  };
  handleExpectedDateChange = date => {
    this.setState({
      expectedPeriod: date
    });
  };
  handleChange = e => {
    const {
      target: { name, value }
    } = e;
    this.setState({
      [name]: value
    });
  };
  render() {
    const {
      closeModal,
      slotID,
      // columns,
      // details,
      // periodID,
      slotName
    } = this.props;
    const { today, plannedPeriod, updatePeriod } = this.state;

    return (
      <Wrapper>
        <div className="modalContent">
          <div className="modalTitle">
            <span>&nbsp;&nbsp;&nbsp;&nbsp;Edit ({slotName})</span>
            <i
              role="presentation"
              className="demo-icon icon-cancel close"
              onClick={() => closeModal()}
              title="Close"
            />
          </div>

          <div className="modelsubtitle">
            <div>
              <label>Planned Week</label>
              <DatePicker
                selected={this.state.plannedPeriod}
                minDate={today}
                onChange={this.handlePlannedDateChange}
                dateFormat={window.userContext.dateFormat}
                disabled={!updatePeriod}
                showWeekNumbers
                locale="en-gb"
                filterDate={isWeekday}
              />
              {/*
                <span> </span>
              */}
            </div>
          </div>
          <div className="modelsubtitle">
            <div>
              <label>Samples</label>
              <span>
                <input
                  type="text"
                  defaultValue={this.state.samples}
                  name="samples"
                  onChange={this.handleChange}
                />
              </span>
            </div>
          </div>
          <div className="modalFooter">
            <button
              onClick={() => {
                if (this.state.plannedPeriod === null) return;
                this.props.updateSlot({
                  slotID,
                  plannedDate: updatePeriod
                    ? this.state.plannedPeriod.format(
                        window.userContext.dateFormat
                      ) // eslint-disable-line
                    : null,
                  currentYear: this.props.currentYear,
                  nrOfTests: this.state.samples,
                  forced: this.props.forced
                });
              }}
            >
              Update
            </button>
          </div>
          {/*
          <div className="update-slot-period-modal-footer"> </div>
          */}
        </div>
      </Wrapper>
    );
  }
}

LabOverviewSlotUpdateModal.defaultProps = {
  slotID: null,
};
LabOverviewSlotUpdateModal.propTypes = {
  plannedDate: PropTypes.string.isRequired,
  slotName: PropTypes.string.isRequired,
  updatePeriod: PropTypes.bool.isRequired,

  closeModal: PropTypes.func.isRequired,
  updateSlot: PropTypes.func.isRequired,
  currentYear: PropTypes.number.isRequired,
  slotID: PropTypes.number,
  samples: PropTypes.oneOfType([PropTypes.number, PropTypes.string]).isRequired,
  forced: PropTypes.bool.isRequired
};
export default LabOverviewSlotUpdateModal;
