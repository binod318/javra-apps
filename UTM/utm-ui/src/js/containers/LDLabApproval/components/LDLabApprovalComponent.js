import React from "react";
import shortid from "shortid";
import PropTypes from "prop-types";

import UpdateSlotPeriodModal from "../containers/UpdateSlotPeriodModal";
import SelectPlanPeriod from "./SelectPlanPeriod";
import SummaryTable from "./SummaryTable";
import DetailsTable from "./DetailsTable";
import { localStorageService } from "../../../services/local-storage.service"

class LDLabApprovalComponent extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      selectedPeriodID: 0,
      planPeriods: [],
      currentSlotID: null,
      updateSlotPeriodModalVisibility: false,
      calWidth: this.colWidth,
      columnsLength: this.props.columns.length,
      siteLocation: 0,
      location: props.location
    };
    this.colWidth = 105;
  }
  componentDidMount() {
    this.props.getLDPlanPeriods();
    this.props.locationFetch();
    window.addEventListener("resize", this.getNewColWidth);
    this.getNewColWidth();
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.planPeriods.length !== this.state.planPeriods.length) {
      this.setState({
        planPeriods: nextProps.planPeriods
      });
      const selectedPeriod = nextProps.planPeriods.find(
        period => period.selected
      );
      if (selectedPeriod) {
        this.setState({
          selectedPeriodID: selectedPeriod.periodID
        });
        this.initiateFetch(selectedPeriod.periodID, this.state.location);
      }
    }
    if (nextProps.columns.length !== this.props.columns.length) {
      this.setState({
        columnsLength: nextProps.columns.length
      });
      this.getNewColWidth(null, nextProps.columns.length);
    }

    if (nextProps.location != this.props.location && nextProps.location.length > 0) {
      this.setState({location: nextProps.location});
      //trigger data fetch
      this.initiateFetch(this.state.selectedPeriodID, nextProps.location);
    }
  }

  componentWillUnmount() {
    window.removeEventListener("resize", this.getNewColWidth);
  }

  initiateFetch(periodID, locationList) {
    let location = localStorageService.get("siteLocation");
    if(location == undefined)
      location = locationList[0].siteID;

    var siteID = parseInt(location, 10);
    this.setState({siteLocation: siteID});

    if(periodID > 0)
      this.props.getLDApprovalList(periodID, siteID);
  }

  getNewColWidth = (e = null, colLength = null) => {
    // eslint-disable-line
    const { innerWidth } = window;
    const columnsLength = colLength || this.state.columnsLength;
    // hard code
    // 040 wrapper padding
    // 315 (date section)
    // 105 (user col) +
    // 420 (comment section)
    const fixWidth = 950;
    // const fixWidth = 880 + 17;
    if (columnsLength > 0) {
      const newCal = (innerWidth - fixWidth) / columnsLength;
      if (newCal > this.colWidth) {
        this.setState({
          calWidth: Math.ceil(newCal)
        });
      } else if (this.state.calWidth !== 105) {
        this.setState({
          calWidth: 105
        });
      }
    }
  };
  handleChoosePeriodChange = e => {
    this.setState({
      selectedPeriodID: e.target.value * 1
    });

    if(this.state.siteLocation > 0)
      this.props.getLDApprovalList(e.target.value, this.state.siteLocation);
  };
  changeLocation = e => {
    const siteLocation = e.target.value;

    //store location on local storage
    localStorageService.set("siteLocation", siteLocation);
    this.setState({ siteLocation });

    if (this.state.selectedPeriodID > 0)
      this.props.getLDApprovalList(this.state.selectedPeriodID, siteLocation);
  };
  showUpdateSlotPeriodModal = slotID => {
    this.setState({
      currentSlotID: slotID,
      updateSlotPeriodModalVisibility: true
    });
  };
  closeUpdateSlotPeriodModal = () => {
    this.setState({
      updateSlotPeriodModalVisibility: false
    });
  };

  render() {
    const {
      columns,
      standard,
      current,
      planPeriods,
      details,
      approveLDSlot,
      denyLDSlot,
      location
    } = this.props;
    const { calWidth, siteLocation } = this.state;
    const columnsName = [];
    const keys = [];
    columns.map(column => {
      columnsName.push(
        <th style={{ width: calWidth }} key={column.testProtocolID}>
          {column.testProtocolName}
        </th>
      );
      keys.push(column.testProtocolID);
      return null;
    });

    const requestedRecordColumnsMap = this.props.columns.reduce(
      (mapObject, column) => {
        mapObject.plannedPeriodColumns.push(column);
        return mapObject;
      },
      {
        plannedPeriodColumns: []
      }
    );
    return (
      <div className="labApproval">
        <section className="page-action">
          <div className="left">
            <SelectPlanPeriod
              {...{
                onChange: this.handleChoosePeriodChange,
                selectedPeriodID: this.state.selectedPeriodID,
                planPeriods,
                siteLocation,
                location,
                changeLocation:this.changeLocation
              }}
            />
          </div>
        </section>

        <div className="lab-approval-main-wrapper">
          {this.state.updateSlotPeriodModalVisibility && (
            <UpdateSlotPeriodModal
              {...{
                closeModal: this.closeUpdateSlotPeriodModal,
                slotID: this.state.currentSlotID,
                periodID: this.state.selectedPeriodID
              }}
            />
          )}
          {standard.map(standardItem => {
            const currentItem = current.find(
              aItem => aItem.periodID === standardItem.periodID
            );

            const currentPeriodDetails = [];
            details.map(detailsItem => {
              if (detailsItem.periodID === standardItem.periodID) {
                currentPeriodDetails.push(detailsItem);
              }
              return null;
            });
            return (
              <div
                key={shortid.generate()}
                className="lab-approval-table-container"
              >
                <div className="lap-approval-tables-wrapper">
                  <SummaryTable
                    {...{
                      columnsName,
                      keys,
                      standardItem,
                      currentItem,
                      calWidth
                    }}
                  />
                  {currentPeriodDetails.length > 0 && (
                    <DetailsTable
                      {...{
                        columnsName,
                        keys,
                        currentPeriodDetails,
                        periodID: this.state.selectedPeriodID,
                        siteID: this.state.siteLocation,
                        approveLDSlot,
                        denyLDSlot,
                        showUpdateSlotPeriodModal: this
                          .showUpdateSlotPeriodModal,
                        standardItem,
                        calWidth,
                        requestedRecordColumnsMap
                      }}
                    />
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    );
  }
}
LDLabApprovalComponent.propTypes = {
  sidemenu: PropTypes.func.isRequired,
  getLDApprovalList: PropTypes.func.isRequired,
  approveLDSlot: PropTypes.func.isRequired,
  denyLDSlot: PropTypes.func.isRequired,
  getLDPlanPeriods: PropTypes.func.isRequired,
  current: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  standard: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  details: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  columns: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  planPeriods: PropTypes.array.isRequired // eslint-disable-line react/forbid-prop-types
};
export default LDLabApprovalComponent;
