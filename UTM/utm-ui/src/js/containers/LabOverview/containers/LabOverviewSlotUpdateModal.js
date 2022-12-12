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
      expectedPeriod: moment(props.expectedDate, window.userContext.dateFormat),
      plates: props.plates,
      markers: props.markers,
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
              <label>Expected Week</label>
              <span>
                <DatePicker
                  selected={this.state.expectedPeriod}
                  minDate={plannedPeriod}
                  onChange={this.handleExpectedDateChange}
                  disabled={!updatePeriod}
                  dateFormat={window.userContext.dateFormat}
                  showWeekNumbers
                  locale="en-gb"
                  filterDate={isWeekday}
                />
              </span>
            </div>
            <div />
          </div>
          <div className="modelsubtitle">
            <div className="formFix">
              <div>
                <label>Tests</label>
                <span>
                  <input
                    type="text"
                    defaultValue={this.state.markers}
                    name="markers"
                    onChange={this.handleChange}
                  />
                </span>
              </div>
              <div>
                <label>Plates</label>
                <span>
                  <input
                    type="text"
                    defaultValue={this.state.plates}
                    name="plates"
                    onChange={this.handleChange}
                  />
                </span>
              </div>
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
                  expectedDate: updatePeriod
                    ? this.state.expectedPeriod.format(
                        window.userContext.dateFormat
                      ) // eslint-disable-line
                    : null,
                  currentYear: this.props.currentYear,
                  nrOfPlates: this.state.plates,
                  nrOfTests: this.state.markers,
                  forced: this.props.forced
                });
                // closeModal();
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
  expectedDate: ""
};
LabOverviewSlotUpdateModal.propTypes = {
  plannedDate: PropTypes.string.isRequired,
  expectedDate: PropTypes.string,
  slotName: PropTypes.string.isRequired,
  updatePeriod: PropTypes.bool.isRequired,

  closeModal: PropTypes.func.isRequired,
  updateSlot: PropTypes.func.isRequired,
  currentYear: PropTypes.number.isRequired,
  // updateSlotPeriod: PropTypes.func.isRequired,
  // periodID: PropTypes.number.isRequired,
  slotID: PropTypes.number,
  markers: PropTypes.oneOfType([PropTypes.number, PropTypes.string]).isRequired,
  plates: PropTypes.oneOfType([PropTypes.number, PropTypes.string]).isRequired,
  forced: PropTypes.bool.isRequired
  // details: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  // columns: PropTypes.array.isRequired // eslint-disable-line react/forbid-prop-types
};
export default LabOverviewSlotUpdateModal;
// const mapStateToProps = state => ({
//   details: state.approvalList.details,
//   columns: state.approvalList.columns
// });
// const mapDispatchToProps = {
//   updateSlotPeriod
// };

// export default connect(mapStateToProps, mapDispatchToProps)(
//   LabOverviewSlotUpdateModal
// );
