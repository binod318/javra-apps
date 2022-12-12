import React from "react";
import { connect } from "react-redux";
import shortid from "shortid";
import moment from "moment";
import DatePicker from "react-datepicker";
import PropTypes from "prop-types";
import { updateLDSlotPeriod } from "../actions";
import { isWeekday } from "../../../helpers/helper";
class UpdateSlotPeriodModal extends React.Component {
  constructor(props) {
    super(props);
    const currentSlotDetails = props.details.find(
      item => item.slotID === props.slotID
    );
    this.state = {
      today: moment(),
      plannedPeriod: moment(
        currentSlotDetails.plannedDate,
        window.userContext.dateFormat
      )
    };
  }
  handlePlannedDateChange = date => {
    this.setState({
      plannedPeriod: date
    });
  };

  render() {
    const { closeModal, slotID, columns, details, periodID } = this.props;
    const columnsName = [];
    const keys = [];
    columns.map(column => {
      columnsName.push(
        <span key={column.testProtocolID}>{column.testProtocolName}</span>
      );
      keys.push(column.testProtocolID);
      return null;
    });
    const currentSlotDetails = details.find(item => item.slotID === slotID);
    return (
      <div className="update-slot-period-modal">
        <div className="update-slot-period-modal-content">
          <div className="update-slot-period-modal-title">
            <span
              className="update-slot-period-modal-close"
              onClick={closeModal}
              tabIndex="0"
              onKeyDown={() => {}}
              role="button"
            >
              &times;
            </span>
            <span>Update Slot Period</span>
          </div>
          <div className="update-slot-period-modal-body">
            <div>
              <span>Slot Name</span>
              <span>
                <input
                  type="text"
                  value={currentSlotDetails.slotName}
                  disabled
                />
              </span>
            </div>
            <div>
              <span>User</span>
              <span>
                <input
                  type="text"
                  value={
                    currentSlotDetails.requestUser.split("\\")[1] ||
                    currentSlotDetails.requestUser
                  }
                  disabled
                />
              </span>
            </div>
            {keys.map((key, i) => (
              <div key={shortid.generate()}>
                <span>{columnsName[i]}</span>
                <span>
                  <input
                    type="text"
                    value={
                      currentSlotDetails ? currentSlotDetails[key] || "" : ""
                    }
                    disabled
                  />
                </span>
              </div>
            ))}
            <div>
              <span>&gt;1 week</span>
              <span>
                <input
                  type="text"
                  value={currentSlotDetails.totalWeeks > 1 ? "Yes" : "No"}
                  disabled
                />
              </span>
            </div>
            <div>
              <span>#Samples</span>
              <span>
                <input
                  type="text"
                  value={currentSlotDetails.samples}
                  disabled
                />
              </span>
            </div>
            <div>
              <span>Method</span>
              <span>
                <input
                  type="text"
                  value={currentSlotDetails.testProtocolName}
                  disabled
                />
              </span>
            </div>
          </div>
          <div className="update-slot-period-modal-footer">
            <div>
              <span>Planned Week</span>
              <span>
                <DatePicker
                  selected={this.state.plannedPeriod}
                  minDate={this.state.today}
                  onChange={this.handlePlannedDateChange}
                  dateFormat={window.userContext.dateFormat}
                  showWeekNumbers
                  locale="en-gb"
                  filterDate={isWeekday}
                />
              </span>
            </div>
            <div>
              <br />
              <span className="span-with-update-btn">
                <button
                  onClick={() => {
                    if (this.state.plannedPeriod === null) return;
                    this.props.updateLDSlotPeriod(
                      slotID,
                      periodID,
                      currentSlotDetails.siteID,
                      this.state.plannedPeriod.format(
                        window.userContext.dateFormat
                      )
                    );
                    closeModal();
                  }}
                >
                  Update
                </button>
              </span>
            </div>
          </div>
        </div>
      </div>
    );
  }
}
const mapStateToProps = state => ({
  details: state.ldApprovalList.details,
  columns: state.ldApprovalList.columns
});
const mapDispatchToProps = {
  updateLDSlotPeriod
};
UpdateSlotPeriodModal.defaultProps = {
  slotID: null
};
UpdateSlotPeriodModal.propTypes = {
  closeModal: PropTypes.func.isRequired,
  updateSlotPeriod: PropTypes.func.isRequired,
  periodID: PropTypes.number.isRequired,
  slotID: PropTypes.number,
  details: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  columns: PropTypes.array.isRequired // eslint-disable-line react/forbid-prop-types
};
export default connect(
  mapStateToProps,
  mapDispatchToProps
)(UpdateSlotPeriodModal);
