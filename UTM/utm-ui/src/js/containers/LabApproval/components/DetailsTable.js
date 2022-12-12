/**
 * Created by sushanta on 3/29/18.
 */
import React from "react";
import PropTypes from "prop-types";
import shortid from "shortid";
import ConfirmBox from "../../../components/Confirmbox/confirmBox";

class DetailsTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      approveSlotConfirmBoxVisibility: false,
      denySlotConfirmBoxVisibility: false,
      currentSlotID: null,
      forced: false
    };
  }

  getSlotApprovalAndColorIndicators = periodDetailsItem => {
    const hasWeekExceeded =
      periodDetailsItem.calculationFor === "PlannedPeriod" &&
      periodDetailsItem.totalWeeks <= 1;

    const isRecordOfExpectedPeriod =
      periodDetailsItem.calculationFor.toLowerCase() === "expectedperiod";
    const isRecordOfPlannedPeriod = !isRecordOfExpectedPeriod;

    const hasExpectedPeriodExceeded = periodDetailsItem.expectedExceed !== "";

    const hasPlannedPeriodExceeded = periodDetailsItem.plannedExceed !== "";

    const isApproveAllowed =
      hasWeekExceeded ||
      (isRecordOfExpectedPeriod && hasExpectedPeriodExceeded) ||
      (isRecordOfPlannedPeriod && hasPlannedPeriodExceeded);
    return {
      hasWeekExceeded,
      isApproveAllowed,
      hasExpectedPeriodExceeded,
      hasPlannedPeriodExceeded,
      isRecordOfExpectedPeriod,
      isRecordOfPlannedPeriod
    };
  };
  handleSlotApproval = condition => {
    if (condition) {
      this.props.approveSlot(
        this.state.currentSlotID,
        this.props.periodID,
        this.state.forced
      );
    }
    this.setState({
      approveSlotConfirmBoxVisibility: false,
      forced: false
    });
  };
  handleSlotDenial = condition => {
    if (condition) {
      this.props.denySlot(this.state.currentSlotID, this.props.periodID);
    }
    this.setState({
      denySlotConfirmBoxVisibility: false
    });
  };
  render() {
    const {
      columnsName,
      currentPeriodDetails,
      showUpdateSlotPeriodModal,
      calWidth
    } = this.props;
    const { forced, currentSlotID } = this.state;

    let approveMessage = "Do you really want to approve this slot?";
    if (currentSlotID !== null && forced) {
      const currentSlot = this.props.currentPeriodDetails.find(
        slot => slot.slotID === currentSlotID
      );
      if (currentSlot) {
        approveMessage = `Slot exceed the capacity of Plate for date ${
          currentSlot.plannedDate
        } and Marker for date ${
          currentSlot.expectedDate
        } . Do you want to approve for both week?`;
      }
    }
    return (
      <div className="lab-approval-table lab-approval-details-table">
        {this.state.approveSlotConfirmBoxVisibility && (
          <ConfirmBox
            click={this.handleSlotApproval}
            message={approveMessage}
          />
        )}
        {this.state.denySlotConfirmBoxVisibility && (
          <ConfirmBox
            click={this.handleSlotDenial}
            message="Do you really want to deny this slot?"
          />
        )}
        <table>
          <thead
            style={
              currentPeriodDetails.length > 5 ? { overflowY: "scroll" } : {}
            }
          >
            <tr>
              <th>Actions</th>
              <th>Slot Name</th>
              <th>User</th>
              {columnsName}
              <th>&gt;1 week</th>
              <th>#Markers</th>
              <th>#Plates</th>
              <th>Method</th>
            </tr>
          </thead>
          <tbody>
            {currentPeriodDetails.map(periodDetailsItem => {
              const {
                hasWeekExceeded,
                isApproveAllowed,
                hasExpectedPeriodExceeded,
                hasPlannedPeriodExceeded,
                isRecordOfExpectedPeriod,
                isRecordOfPlannedPeriod
              } = this.getSlotApprovalAndColorIndicators(periodDetailsItem);
              const { requestedRecordColumnsMap } = this.props;
              return (
                <tr key={shortid.generate()} t={periodDetailsItem.slotID}>
                  <td>
                    <i
                      role="button"
                      tabIndex="0"
                      onKeyDown={() => {}}
                      onClick={() => {
                        this.setState({
                          denySlotConfirmBoxVisibility: true,
                          currentSlotID: periodDetailsItem.slotID
                        });
                      }}
                      title="Deny Slot"
                      className="icon icon-cancel lab-approval-deny-slot"
                    />{" "}
                    <i
                      role="button"
                      tabIndex="0"
                      onKeyDown={() => {}}
                      onClick={() =>
                        showUpdateSlotPeriodModal(periodDetailsItem.slotID)
                      }
                      title="Update Slot Period"
                      className="icon icon-pencil lab-approval-update-slot"
                    />{" "}
                    {isApproveAllowed && (
                      <span>
                        <i
                          role="button"
                          tabIndex="0"
                          onKeyDown={() => {}}
                          onClick={() => {
                            console.log(periodDetailsItem.slotID);
                            this.setState({
                              approveSlotConfirmBoxVisibility: true,
                              currentSlotID: periodDetailsItem.slotID,
                              forced:
                                periodDetailsItem.expectedExceed !== "" &&
                                periodDetailsItem.plannedExceed !== ""
                            });
                          }}
                          title="Approve Slot"
                          className="icon icon-ok-circled lab-approval-approve-slot"
                        />
                      </span>
                    )}
                  </td>
                  <td className="fixed-one">{periodDetailsItem.slotName}</td>
                  <td className="fixed-one">
                    {periodDetailsItem.requestUser.split("\\")[1] ||
                      periodDetailsItem.requestUser}
                  </td>
                  {requestedRecordColumnsMap &&
                    requestedRecordColumnsMap.expedtedPeriodColumns.map(col => (
                      <td
                        style={{
                          width: calWidth,
                          // eslint-disable-next-line no-nested-ternary
                          color: isRecordOfExpectedPeriod
                            ? hasExpectedPeriodExceeded
                              ? "red"
                              : "initial"
                            : hasExpectedPeriodExceeded
                            ? "blue"
                            : "initial"
                        }}
                        key={col.testProtocolID}
                      >
                        {periodDetailsItem
                          ? periodDetailsItem[col.testProtocolID] || ""
                          : ""}
                      </td>
                    ))}
                  {requestedRecordColumnsMap &&
                    requestedRecordColumnsMap.plannedPeriodColumns.map(col => (
                      <td
                        style={{
                          width: calWidth,
                          // eslint-disable-next-line no-nested-ternary
                          color: isRecordOfPlannedPeriod
                            ? hasPlannedPeriodExceeded
                              ? "red"
                              : "initial"
                            : hasPlannedPeriodExceeded
                            ? "blue"
                            : "initial"
                        }}
                        key={col.testProtocolID}
                      >
                        {periodDetailsItem
                          ? periodDetailsItem[col.testProtocolID] || ""
                          : ""}
                      </td>
                    ))}

                  <td
                    style={{
                      color: hasWeekExceeded ? "red" : "initial"
                    }}
                  >
                    {periodDetailsItem.totalWeeks > 1 ? "Yes" : "No"}
                  </td>
                  <td>{periodDetailsItem.markers}</td>
                  <td>{periodDetailsItem.plates}</td>
                  <td className="fixed-one">
                    {periodDetailsItem.testProtocolName}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    );
  }
}
DetailsTable.defaultProps = {
  calWidth: null
};
DetailsTable.propTypes = {
  currentPeriodDetails: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  columnsName: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  approveSlot: PropTypes.func.isRequired,
  denySlot: PropTypes.func.isRequired,
  showUpdateSlotPeriodModal: PropTypes.func.isRequired,
  periodID: PropTypes.number.isRequired,
  calWidth: PropTypes.number,
  requestedRecordColumnsMap: PropTypes.shape({
    expedtedPeriodColumns: PropTypes.array,
    plannedPeriodColumns: PropTypes.array
  }).isRequired // eslint-disable-line react/forbid-prop-types
};
export default DetailsTable;
