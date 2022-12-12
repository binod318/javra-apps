import React, { Fragment } from "react";

import { getDim } from "../../helpers/helper";
import ActionBar from "../../components/ActionBar/ActionBar";
import TabelGrid from "../../components/TableGrid/TableGrid";
import Decluster from "./DeclusterComponent";

import { platePlanOverViewAPI } from "./labPreparationApi";
import { withAITracking } from '@microsoft/applicationinsights-react-js';
import { reactPlugin, appInsights } from '../../config/app-insights-service';

class LabPreparationComponent extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      selected: props.selected,
      year: props.year,
      periodSelected: props.periodSelected,
      period: props.period,

      fetch: false,

      tblWidth: 900,
      tblHeight: 600,

      showDecluster: false,
      detAssignmentID: "",
    };
  }

  componentDidMount() {
    appInsights.trackPageView({ name: 'LabPreparation' });
    window.addEventListener("beforeunload", this.handleWindowClose);
    window.addEventListener("resize", this.updateDimensions);
    if (this.props.selected === "" || !this.props.year.length) {
      this.props.labPreparationYearFetch();
    }
    if (this.props.selected !== "" && this.props.periodSelected === "") {
      this.props.labPreparationPeriodFetch(this.props.selected);
    }
    if (this.props.selected !== "" && this.props.periodSelected !== "") {
      const row = this.props.period.find(
        (t) => t.PeriodID == this.props.periodSelected
      );
      this.props.labPreparationFolderFetch(this.props.periodSelected);
    }
    this.updateDimensions();
  }

  componentWillReceiveProps(nextProps) {
    if (this.props.selected !== nextProps.selected) {
      const { year, selected } = nextProps;
      this.setState({ year, selected });
      this.props.labPreparationPeriodBlank();
      this.props.labPreparationPeriodFetch(selected);
    }
    if (this.props.periodSelected !== nextProps.periodSelected) {
      const { period, periodSelected } = nextProps;
      this.setState({ period, periodSelected });
      if (periodSelected !== "")
        this.props.labPreparationFolderFetch(periodSelected);
      this.updateDimensions();
    }
  }

  componentWillUnmount() {
    window.removeEventListener("beforeunload", this.handleWindowClose);
    window.removeEventListener("resize", this.updateDimensions);
  }

  updateDimensions = () => {
    const { width: tblWidth, height: tblHeight } = getDim();
    this.setState({ tblWidth, tblHeight });
  };
  handleWindowClose = (e) => {
    if (this.props.isChange) {
      e.returnValue = "blocked";
    }
  };

  changeYear = (e) => {
    this.props.labPreparationYearSelect(e.target.value);
  };
  changePeriod = (e) => {
    const row = this.state.period.find((t) => t.PeriodID == e.target.value);
    this.props.labPreparationPeriodSelect(e.target.value, row);
  };

  getTable = () => {
    const newList = [];
    this.props.groups.map((g) => {
      const { open, id } = g;
      const arrangedList = [];
      newList.push(g);
      if (open) {
        this.props.data.map((d) => {
          const {
            TestName,
            ABSCropCode,
            MethodCode,
            PlatformName,
            TestID,
            IsLabPriority,
            IsParent,
            DetAssignmentID,
            NrOfPlates,
            NrOfMarkers,
            TraitMarkers,
            VarietyName,
            SampleNr,
            PlateNames,
          } = d;
          const arrange = IsLabPriority ? "true" : "false";
          if (id === TestID) {
            arrangedList.push({
              DetAssignmentID,
              NrOfPlates,
              NrOfMarkers,
              TraitMarkers,
              VarietyName,
              SampleNr,
              IsLabPriority,
              IsParent,
              PlateNames,
            });
          }
          return null;
        });
        const res = arrangedList
          .sort((a, b) => {
            return b.IsLabPriority - a.IsLabPriority || b.IsParent - a.IsParent;
          })
          .map((r) => {
            newList.push(r);
          });
      }
      return null;
    });

    return newList;
  };

  reservePlatesFunc = () => {
    const { periodSelected } = this.state;
    this.props.reservePlates(periodSelected);
  };
  sendToLimsFunc = () => {
    const { periodSelected } = this.state;
    this.props.sendToLims(periodSelected);
  };

  leftSection = () => {
    const { year, selected, period, periodSelected } = this.state;
    const { totalUsed, totalReserved } = this.props;
    return (
      <Fragment>
        <div className='form-e'>
          <label htmlFor='year'>Year</label>
          <select
            id='year'
            name='year'
            onChange={this.changeYear}
            value={selected}
          >
            {year.map((y) => (
              <option key={y.Year} value={y.Year}>
                {y.Year}
              </option>
            ))}
          </select>
        </div>
        <div className='form-e'>
          <label htmlFor='year'>Period</label>
          <select
            id='peroid'
            name='period'
            onChange={this.changePeriod}
            value={periodSelected}
          >
            <option value=''>--</option>
            {period.map((p) => (
              <option key={p.PeriodID} value={p.PeriodID}>
                {p.PeriodName}
              </option>
            ))}
          </select>
        </div>
        <div className="form-e">
          <label htmlFor='fillRate' className="full">
            Fill Rate
            {": "}
            {`${totalUsed}/${totalReserved}`}
          </label>
        </div>
      </Fragment>
    );
  };

  rightSection = () => {
    const { role, status: testStatusCode, daStatus: daStatusCode } = this.props;
    const { periodSelected } = this.state;

    const roleAccess = role.includes("pac_requestlims");

    //Reserve button status check from Determination Assignment level
    const status150 = roleAccess ? (testStatusCode < 200 && daStatusCode === 300) : roleAccess; //declustered

    //Send to LIMS and other button status check from Test level
    const status350 = roleAccess ? testStatusCode === 350 : roleAccess; // Platefilling;
    const stausGreaterOrEqual300 = testStatusCode >= 300; //Received

    return (
      <Fragment>
        <button
          className='with-i'
          disabled={!status150}
          onClick={this.reservePlatesFunc}
        >
          <i className='demo-icon icon-ok-circled' />
          Reserve Plates
        </button>
        <button
          className='with-i'
          disabled={!status350}
          onClick={this.sendToLimsFunc}
        >
          <i className='demo-icon icon-paper-plane' />
          Send to LIMS
        </button>
        <button
          className='with-i'
          disabled={!stausGreaterOrEqual300}
          onClick={() => platePlanOverViewAPI(periodSelected)}
        >
          <i className='demo-icon icon-file-pdf' />
          Plate Plan Overview
        </button>
        <button
          className='with-i'
          disabled={!stausGreaterOrEqual300}
          onClick={() => this.props.postPrintPlateLabel(periodSelected, "")}
        >
          <i className='demo-icon icon-print' />
          Print Label
        </button>
      </Fragment>
    );
  };

  render() {
    const { tblHeight, tblWidth, periodSelected } = this.state;
    const customWidth = {
      DetAssignmentID: 130,
      SampleNr: 80,
      VarietyNr: 80,
      ProcessNr: 80,
      Action: 81,
      PlatformName: 160,
      VarietyName: 260,
      TestName: 130,
      TraitMarkers: 100,
      PlateNames: 280,
    };
    return (
      <Fragment>
        <div>
          <ActionBar left={this.leftSection} right={this.rightSection} />
          <div className='container'>
            <br />
            <div>
              <TabelGrid
                customWidth={customWidth}
                tblWidth={tblWidth}
                tblHeight={tblHeight}
                isChange={false}
                changeValue={() => {}}
                sideMenu={this.props.sideMenu}
                data={this.getTable()}
                columns={this.props.columns}
                action={{
                  name: "folder",
                  open: (index) => this.props.groupToggle(index),
                  view: (DetAssignmentID) => {
                    this.setState({
                      detAssignmentID: DetAssignmentID,
                      showDecluster: true,
                    });
                  },
                  edit: () => alert("edit"),
                  print: (TestID) => {
                    this.props.postPrintPlateLabel(periodSelected, TestID);
                  },
                }}
              />
            </div>
          </div>
        </div>
        {this.state.showDecluster && (
          <Decluster
            PeriodID={this.state.periodSelected}
            DetAssignmentID={this.state.detAssignmentID}
            closeFunc={() => this.setState({ showDecluster: false })}
            detAssignMentIdFunc={() => {
              this.setState({ detAssignmentID: "" });
            }}
            getTableFunc={this.getTable}
            groupToggle={() => {}}
            fetch={this.props.labDeclusterFetch}
            data={this.props.ddata}
            columns={this.props.dcolumns}
          />
        )}
      </Fragment>
    );
  }
}

export default withAITracking(reactPlugin, LabPreparationComponent);
/*
Folder
Crop
Method
Platform
Plates
markers
Trait Markers
Variety
*/
