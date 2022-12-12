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
    const hasWeekExceeded = periodDetailsItem.totalWeeks <= 1;
    const hasPlannedPeriodExceeded = periodDetailsItem.plannedExceed !== "";
    const isApproveAllowed = hasWeekExceeded || hasPlannedPeriodExceeded;

    return {
      hasWeekExceeded,
      isApproveAllowed,
      hasPlannedPeriodExceeded
    };
  };
  handleSlotApproval = condition => {
    if (condition) {
      this.props.approveLDSlot(
        this.state.currentSlotID,
        this.props.periodID,
        this.props.siteID,
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
      this.props.denyLDSlot(this.state.currentSlotID, this.props.periodID, this.props.siteID);
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
        if(currentSlot.totalWeeks<=1){
          approveMessage = `Slot falls within two weeks range for date ${
            currentSlot.plannedDate
          } . Do you want to approve?`;
        }
        else{
          approveMessage = `Slot exceed the capacity of sample for date ${
            currentSlot.plannedDate
          } . Do you want to approve?`;

        }
        
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
              <th>#Samples</th>
              <th>Method</th>
            </tr>
          </thead>
          <tbody>
            {currentPeriodDetails.map(periodDetailsItem => {
              const {
                hasWeekExceeded,
                isApproveAllowed,
                hasPlannedPeriodExceeded
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
                                //periodDetailsItem.expectedExceed !== "" &&
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
                    requestedRecordColumnsMap.plannedPeriodColumns.map(col => (
                      <td
                        style={{
                          width: calWidth,
                          // eslint-disable-next-line no-nested-ternary
                          color: hasPlannedPeriodExceeded
                              ? "red"
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
                  <td>{periodDetailsItem.samples}</td>
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
  approveLDSlot: PropTypes.func.isRequired,
  denyLDSlot: PropTypes.func.isRequired,
  showUpdateSlotPeriodModal: PropTypes.func.isRequired,
  periodID: PropTypes.number.isRequired,
  siteID: PropTypes.number.isRequired,
  calWidth: PropTypes.number,
  requestedRecordColumnsMap: PropTypes.shape({
    plannedPeriodColumns: PropTypes.array
  }).isRequired // eslint-disable-line react/forbid-prop-types
};
export default DetailsTable;
