import React, { Fragment } from "react";

import TableGrid from "../../components/TableGrid/TableGrid";
import { getDim } from "../../helpers/helper";
import ActionBar from "../../components/ActionBar/ActionBar";
import GroupTable from "./Component/GroupTable";
import "./planningbatchesso.scss";
import { withAITracking } from '@microsoft/applicationinsights-react-js';
import { reactPlugin, appInsights } from '../../config/app-insights-service';

class PlanningBatchesSOComponent extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      selected: props.selected,
      year: props.year,
      periodSelected: props.periodSelected,
      period: props.period,
      dateStart: props.dateStart,
      dateEnd: props.dateEnd,
      changes: props.changes,
      refresh: props.refresh,
      fetch: false,
      data: props.data,
      isChange: false,
      tblWidth: 900,
      tblHeight: 600,
      changed: [],
      automaticalPlann: false,
      isPlannedCount: false,
    };
  }

  componentDidMount() {
    appInsights.trackPageView({ name: 'PlanningBatchesSO' });
    window.addEventListener("beforeunload", this.handleWindowClose);
    window.addEventListener("resize", this.updateDimensions);
    if (this.props.selected === "" || !this.props.year.length) {
      this.props.planningYearFetch();
    }
    if (this.props.selected !== "" && this.props.periodSelected === "") {
      this.props.planningPeriodFetch(this.props.selected);
    }
    if (this.props.selected !== "" && this.props.periodSelected !== "") {
      const { periodSelected, dateStart, dateEnd } = this.props;
      this.props.planningDeterminationFetch(
        periodSelected,
        dateStart,
        dateEnd,
        false
      );
    }
    this.updateDimensions();
  }
  componentWillReceiveProps(nextProps) {
    if (this.props.refresh !== nextProps.refresh) {
      this.setState({
        refresh: nextProps.refresh,
        data: nextProps.data,
        changes: nextProps.changes,
      });
    }

    if (this.props.selected !== nextProps.selected) {
      const { year, selected } = nextProps;
      this.setState({ year, selected });
      this.props.planningPeriodBlank();
      this.props.planningPeriodFetch(selected);
    }
    if (this.props.periodSelected !== nextProps.periodSelected) {
      const { period, periodSelected } = nextProps;
      this.setState({ period, periodSelected });
      this.updateDimensions();
    }
    if (this.props.dateStart !== nextProps.dateStart) {
      const { periodSelected, dateStart, dateEnd } = nextProps;
      this.setState({ dateStart, dateEnd });
      this.props.planningDeterminationFetch(
        periodSelected,
        dateStart,
        dateEnd,
        false
      );
    }

    if (nextProps.data.length === 0) {
      this.setState({ isPlannedCount: false });
    }
    if (nextProps.data.length) {
      const that = this;

      nextProps.data.map((d) => {
        if (d.CanEditPlanning) {
          that.setState({
            automaticalPlann: true,
          });
        }
        return null;
      });
      if (nextProps.changes.length) {
        let ff = nextProps.changes.find((c) => {
          return (c.init === true || c.flag === true) && c.can; //  && c.change;
        });

        this.setState({
          isPlannedCount: ff !== undefined ? true : false,
        });
      }
    }
  }

  componentWillUnmount() {
    window.removeEventListener("beforeunload", this.handleWindowClose);
    window.removeEventListener("resize", this.updateDimensions);
    this.props.clearPage();
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
    this.setState({ automaticalPlann: false, isPlannedCount: false });
    this.props.planningYearSelect(e.target.value);
  };
  changePeriod = (e) => {
    const row = this.state.period.find((t) => t.PeriodID == e.target.value);
    this.setState({ automaticalPlann: false, isPlannedCount: false });
    this.props.planningPeriodSelect(e.target.value, row);
  };

  unplannedFunc = () => {
    const { periodSelected, dateStart, dateEnd } = this.state;
    this.props.planningDeterminationFetch(
      periodSelected,
      dateStart,
      dateEnd,
      true
    );
  };
  automaticalFunc = () => {
    const { periodSelected, dateStart, dateEnd } = this.state;
    this.props.autoPlanDeterminationFetch(periodSelected, dateStart, dateEnd);
  };
  confirmFunc = () => {
    const obj = [];
    this.props.changes.map((cc) => {
      if (cc.change || cc.perioChange) {
        const fff = !cc.IsPlanned && cc.flag ? "i" : cc.flag ? "u" : "d";
        obj.push({
          ...cc,
          Action: fff, // cc.flag ? 'u' : 'd'
        });
      }
    });
    const {
      dateEnd: EndDate,
      dateStart: StartDate,
      periodSelected: periodID,
    } = this.state;
    this.props.planningDeterminationConfirmPost(obj, periodID, {
      StartDate,
      EndDate,
    });
  };

  gourpCheckBoxClick = (change, flag) => {
    this.props.planningDataChangePost(change, flag);
  };
  groupLabPrioClick = (change, flag) => {
    this.props.planningDataPrioChangePost(change, flag);
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
    const { automaticalPlann, isPlannedCount } = this.state;

    return (
      <Fragment>
        <button className='with-i' onClick={this.unplannedFunc}>
          <i className='demo-icon icon-spin6' />
          Load unplanned
        </button>
        <button onClick={this.automaticalFunc}>Automatical Plan</button>
        <button
          className='with-i'
          disabled={!isPlannedCount}
          onClick={this.confirmFunc}
        >
          <i className='demo-icon icon-ok-circled' />
          Confirm
        </button>
      </Fragment>
    );
  };

  tableDraw = () => {
    const customWidth = {
      IsLabPriority: 70,
      DetAssignmentID: 130,
      SampleNr: 80,
      PlannedDate: 100,
      UtmostInlayDate: 100,
      ExpectedReadyDate: 120,
      PriorityCode: 50,
      BatchNr: 80,
      RepeatIndicator: 60,
      Article: 180,
      BatchOutputDesc: 200,
      Process: 120,
      ProductStatus: 120,
      IsPlanned: 70,
      Remarks: 350,
    };
    const tblConfig = {};

    const newColumn = this.props.columns
      .filter((x) => x.IsVisible)
      .map((c) => {
        return c;
      });

    return this.props.group.map((g, i) => (
      <GroupTable
        key={i}
        customWidth={customWidth}
        columns={newColumn}
        data={this.props.changes}
        group={g}
        automaticPlan={this.state.automaticalPlann}
        gourpCheckBoxClick={this.gourpCheckBoxClick}
        groupLabPrioClick={this.groupLabPrioClick}
        refresh={this.state.refresh}
        show={this.props.show}
      />
    ));
  };

  render() {
    const { isChange, tblWidth, tblHeight } = this.state;
    const { automaticalPlann, isPlannedCount, changes } = this.state;

    return (
      <div>
        <ActionBar left={this.leftSection} right={this.rightSection} />
        <div className='container'>
          {this.props.group.length ? (
            this.tableDraw()
          ) : (
            <div>
              <div className='container'>
                <br />
                No Data Found.
              </div>
            </div>
          )}

          {/* {this.props.columns && false && <TableGrid tblConfig={tblConfig} customWidth={customWidth} tblWidth={tblWidth} tblHeight={tblHeight} isChange={isChange} changeValue={() => {}} applyToAll={() => {}} sideMenu={this.props.sideMenu} data={this.props.data} columns={this.props.columns} headerHeight={40} />} */}
        </div>
        <br />
      </div>
    );
  }
}

export default withAITracking(reactPlugin, PlanningBatchesSOComponent);
