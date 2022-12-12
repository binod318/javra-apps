import React, { Fragment } from "react";
import PropTypes from "prop-types";
import { Prompt } from "react-router-dom";
import { Table, Column, Cell } from "fixed-data-table-2";
import { v4 as uuidv4 } from "uuid";

import TableGrid from "../../components/TableGrid/TableGrid";
import HeaderCell from "../../components/TableGrid/HeaderCell";
import { getDim, errorStyle, changeStyle } from "../../helpers/helper";
import ActionBar from "../../components/ActionBar/ActionBar";
import { withAITracking } from '@microsoft/applicationinsights-react-js';
import { reactPlugin, appInsights } from '../../config/app-insights-service';

class CapacitySOComponent extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      year: props.year,
      selected: props.selected,
      period: props.period,
      periodSelected: props.periodSelected,
      data: props.data,
      isChange: false,
      tblWidth: 900,
      tblHeight: 600,
      changed: [],
      status: props.status,
      count: props.count,
      focusRef: props.focusRef,
      focusName: "",
    };
    this.checktime = null;
    this.inputRef = React.createRef();
  }

  componentDidMount() {
    appInsights.trackPageView({ name: 'CapacityPlanningSO' });
    window.addEventListener("beforeunload", this.handleWindowClose);
    window.addEventListener("resize", this.updateDimensions);
    if (this.props.selected === "" || !this.props.year.length)
      this.props.capacityYearFetch();

    if (this.props.selected !== "" && this.props.periodSelected === "") {
      this.props.capacityPeriodFetch(this.props.selected);
    }

    if (this.props.selected !== "" && this.props.periodSelected !== "") {
      this.props.capacityFetch(this.props.periodSelected);
    }

    this.updateDimensions();
  }

  componentWillReceiveProps(nextProps) {
    if (this.props.selected !== nextProps.selected) {
      const { year, selected } = nextProps;
      this.setState({ year, selected });
      this.updateDimensions();
      this.props.capacityPeriodFetch(selected);
      this.setState({ isChange: false, changed: [] });
    }

    const { period, periodSelected } = nextProps;
    if (this.props.periodSelected !== nextProps.periodSelected) {
      this.setState({ period, periodSelected });
      this.updateDimensions();
      if (periodSelected !== "") this.props.capacityFetch(periodSelected);
    } else {
      this.setState({ period, periodSelected });
    }

    if (this.props.status !== nextProps.status) {
      if (nextProps.status === "success")
        this.setState({ isChange: false, changed: [] });
    }

    if (nextProps.errList.length > 0) {
      const focusName = nextProps.errList[0];
      document.getElementById(focusName).focus();
    } else {
      this.setState({ focusName: "" });
    }
  }

  componentWillUnmount() {
    window.removeEventListener("beforeunload", this.handleWindowClose);
    window.removeEventListener("resize", this.updateDimensions);
    this.props.capacityEmpty();
  }

  updateDimensions = () => {
    const { width: tblWidth, height: tblHeight } = getDim();
    this.setState({ tblWidth, tblHeight });
  };

  handleWindowClose = (e) => {
    if (this.state.changed.length) {
      e.returnValue = "blocked";
    }
  };

  changeYear = (e) => {
    this.props.capacityEmpty();
    this.props.capacityYearSelect(e.target.value);
  };

  changePeriod = (e) => {
    this.props.capacityEmpty();
    this.props.capacityPeriodSelect(e.target.value);
  };

  addToChange = (p, k, v, i, ov) => {
    const { changed } = this.state;
    const obj = [];

    if (changed.length <= 0) {
      obj.push({ CropMethodID: p, PeriodID: k, Value: v, ov });

      if (v !== ov) this.setState({ isChange: true, changed: obj });
      else this.setState({ isChange: false, changed: obj });
    } else {
      const check = changed.filter(
        (d) => d.CropMethodID === p && d.PeriodID === k
      );
      if (check.length) {
        const newObj = changed.map((d) => {
          if (d.CropMethodID === p && d.PeriodID === k) {
            return { CropMethodID: p, PeriodID: k, Value: v, ov };
          }
          return d;
        });

        if (v !== ov) this.setState({ isChange: true, changed: newObj });
        else this.setState({ isChange: false, changed: newObj });
      } else {
        obj.push.apply(changed, [
          {
            CropMethodID: p,
            PeriodID: k,
            Value: v,
            ov,
          },
        ]);
      }
    }
  };

  handleChange = (total, hybTotal, parTotal, ColumnID) => {
    this.props.totalChange(total, hybTotal, parTotal, ColumnID);
  };
  handleNumberChange = (e, row, ColumnID) => {
    const { id, UsedFor, CropMethodID } = row;
    const { value, name } = e.target;

    this.props.refFunc(name);

    this.props.capacityDataChange(id, ColumnID, value, UsedFor, row[ColumnID]);

    const _this = this;
    clearTimeout(_this.checktime);
    this.checktime = setTimeout(function() {
      _this.blurFunc([
        {
          CropMethodID: row.CropMethodID,
          PeriodID: ColumnID,
          Value: value,
        },
      ]);
    }, 300);
  };

  changeValue = (i, k, v, p, ov) => {
    this.props.capacityDataChange(p.id, k, v, p.UsedFor, ov);
    // PACCropMethodID, PeriodID, Value
    this.addToChange(p.CropMethodID, k, v, i, ov);
  };

  blurFunc = (obj) => {
    this.props.capacityDataUpdate(obj);
  };

  saveChange = () => {
    this.props.capacityDataUpdate(this.state.changed);
  };

  leftSection = () => {
    const { year, selected, period, periodSelected } = this.state;
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
            disabled={this.state.count > 0}
          >
            <option value=''>--</option>
            {period.map((p) => (
              <option key={p.PeriodID} value={p.PeriodID}>
                {p.PeriodName}
              </option>
            ))}
          </select>
        </div>
      </Fragment>
    );
  };

  _rowClassNameGetter = (rowIndex) => {
    const { data } = this.props;
    const { UsedFor, group } = data[rowIndex];

    if (data[rowIndex]["IsLabPriority"]) {
      return "prio-row";
    }
    if (UsedFor && UsedFor.toLowerCase() === "par") return "par-row";
    if (group) return "group-row";
    return "";
  };

  drawCell = (Editable, ColumnID, row) => {
    const { data } = this.props;
    const { changeValue, isChange, focusRef, actionfunc } = this.props;
    const { focusName } = this.state;

    const dvalue = row[ColumnID] || "";

    if (!Editable) {
      return <Cell>{dvalue}</Cell>;
    }
    let match = this.props.errList.includes(row.id + ColumnID) || false;

    return (
      <Cell>
        <input
          type='number'
          value={dvalue}
          name={row.id + ColumnID}
          id={row.id + ColumnID}
          style={match ? errorStyle : {}}
          onChange={(e) => {
            this.handleNumberChange(e, row, ColumnID);
          }}
          onFocus={(e) => {
            e.target.select();
          }}
          min={0}
          onKeyUp={(e) => {}}
        />
      </Cell>
    );
  };

  render() {
    const { changed, isChange } = this.state;
    let { tblWidth, tblHeight } = this.state;
    const customWidth = {
      MethodCode: 123,
      ABSCropCode: 100,
    };

    this.props.columns.map((c) => {
      if (customWidth[c.ColumnID] === undefined) {
        Object.assign(customWidth, { [c.ColumnID]: 110 });
      }
    });

    tblWidth -= 30; // 80
    if (this.props.sideMenu) {
      tblWidth -= 210;
    } else {
      tblWidth -= 60;
    }

    tblHeight -= 120;

    const tblConfig = { toAllBtn: false };
    return (
      <div>
        <Prompt
          message='Changes you made may not be saved.'
          when={this.state.isChange}
        />
        <ActionBar left={this.leftSection} />
        <div className='container'>
          <br />
          <div>
            {this.props.columns && (
              <Table
                rowHeight={40}
                headerHeight={60}
                rowsCount={this.props.data.length}
                width={tblWidth}
                height={tblHeight}
                footerHeight={140}
                rowClassNameGetter={this._rowClassNameGetter}
              >
                {this.props.columns
                  .filter((is) => is.IsVisible)
                  .map((col) => {
                    const { ColumnID, Label, Editable, sort, filter, id } = col;
                    let cellWidth = 80; // Label.length * 12 < 140 ? 140 : Label.length * 12;
                    cellWidth = customWidth[ColumnID] || cellWidth;
                    const fixed = false;

                    return (
                      <Column
                        key={ColumnID}
                        fixed={fixed}
                        flexGrow={0}
                        header={
                          <HeaderCell
                            click={() => {
                              //showApply
                            }}
                            keyValue={ColumnID}
                            view={Label}
                            sort={false}
                            filter={false}
                            filterFunc={() => {}}
                            sortFunc={() => {}}
                          />
                        }
                        columnKey={ColumnID}
                        width={cellWidth}
                        cell={({ rowIndex }) => {
                          return this.drawCell(
                            Editable,
                            ColumnID,
                            this.props.data[rowIndex]
                          );
                        }}
                        footer={(ColumnID) => {
                          const { columnKey } = ColumnID;
                          const df = [];
                          this.props.calc.map((f) => {
                            df.push(
                              <div key={uuidv4()} className='footerCell'>
                                {f[columnKey]}
                              </div>
                            );
                          });
                          return <Cell>{df}</Cell>;
                        }}
                      />
                    );
                  })}
              </Table>
            )}
          </div>
        </div>
      </div>
    );
  }
}

CapacitySOComponent.defaultProps = {
  selected: "",
  year: [],
  data: [],
  isChange: false,
};
CapacitySOComponent.propTypes = {
  sideMenu: PropTypes.bool.isRequired,
  selected: PropTypes.string, // eslint-disable-line react/forbid-prop-types
  year: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  data: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  capacityYearFetch: PropTypes.func.isRequired,
  capacityPeriodSelect: PropTypes.func.isRequired,
  capacityFetch: PropTypes.func.isRequired,
  isChange: PropTypes.bool,
};

export default withAITracking(reactPlugin, CapacitySOComponent);
