import React from "react";
import PropTypes from "prop-types";
import { Prompt } from "react-router-dom";

import TableGrid from "../../components/TableGrid/TableGrid";
import { getDim } from "../../helpers/helper";
import ActionBar from "../../components/ActionBar/ActionBar";
import { withAITracking } from '@microsoft/applicationinsights-react-js';
import { reactPlugin, appInsights } from '../../config/app-insights-service';

class LabComponent extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      // editable: false,
      year: props.year,
      selected: props.selected,
      data: props.data,
      isChange: false,
      tblWidth: 900,
      tblHeight: 600,
      changed: [],
      status: props.status,
      focusName: "123123",
    };
  }

  componentDidMount() {
    appInsights.trackPageView({ name: 'LabCapacity' });
    const { selected, data } = this.props;
    if (selected === "") this.props.labYearFetch();
    if (selected !== "") {
      this.props.labFetch(selected);
    }
    this.updateDimensions();

    window.addEventListener("resize", this.updateDimensions);
    window.addEventListener("beforeunload", this.handleWindowClose);
  }

  UNSAFE_componentWillReceiveProps(nextProps) {
    if (this.props.selected !== nextProps.selected) {
      const { year, selected } = nextProps;
      this.setState({ year, selected });
      this.updateDimensions();
      this.props.labFetch(selected);
    }
    if (nextProps.data) {
      this.setState({ data: nextProps.data });
    }
    if (this.props.status !== nextProps.status) {
      if (nextProps.status === "success")
        this.setState({
          isChange: false,
          changed: [],
        });
    }
  }

  componentWillUnmount() {
    window.removeEventListener("resize", this.updateDimensions);
    window.removeEventListener("beforeunload", this.handleWindowClose);
  }

  updateDimensions = () => {
    const { width: tblWidth, height: tblHeight } = getDim();
    this.setState({ tblWidth, tblHeight });
  };

  handleWindowClose = (e) => {
    if (this.props.isChange) {
      e.returnValue = "blocked";
    }
    return null;
  };

  changeYear = (e) => {
    this.props.labYearSelect(e.target.value);
  };

  addToChange2 = (k, v) => {
    const { changed, data } = this.state;
    if (changed.length <= 0) {
      const obj = data.map((d) => {
        return { PeriodID: d.PeriodID, PlatformID: k, Value: v };
      });

      this.setState({ isChange: true, changed: obj });
    } else {
      const obj2 = changed.filter((d) => d.PlatformID !== k);
      data.map((d) => {
        obj2.push({ PeriodID: d.PeriodID, PlatformID: k, value: v });
        return null;
      });
      this.setState({ isChange: true, changed: obj2 });
    }
    this.props.labDataRowChange(k, v);
  };

  addToChange = (p, k, v, i) => {
    const { changed } = this.state;
    const obj = [];

    if (changed.length <= 0) {
      obj.push({
        PeriodID: p,
        PlatformID: k,
        value: v,
      });
      this.setState({ isChange: true, changed: obj });
    } else {
      const check = changed.filter(
        (d) => d.PeriodID === p && d.PlatformID === k
      );
      if (check.length) {
        const newObj = changed.map((d) => {
          if (d.PeriodID === p && d.PlatformID === k) {
            return { PeriodID: p, PlatformID: k, value: v };
          }
          return d;
        });
        this.setState({ isChange: true, changed: newObj });
      } else {
        obj.push.apply(changed, [
          {
            PeriodID: p,
            PlatformID: k,
            value: v,
          },
        ]);
      }
    }
  };

  changeValue = (i, k, v, p) => {
    this.props.labDataChange(i, k, v);
    this.addToChange(p.PeriodID, k, v, i);
  };

  saveChange = () => {
    this.props.labDataUpdate(this.state.changed, this.currentYear);
  };

  setFocusName = (focusName) => {
    this.setState((state) => {
      return {
        focusName,
      };
    });
  };

  leftSection = () => {
    const { year, selected } = this.state;
    return (
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
    );
  };
  rightSection = () => {
    const { isChange } = this.state;
    return (
      <button className='with-i' disabled={!isChange} onClick={this.saveChange}>
        <i className='icon icon-floppy-1' />
        Save
      </button>
    );
  };

  render() {
    const { isChange, tblWidth, tblHeight } = this.state;
    const customWidth = {
      PeriodName: 260,
      "8": 140,
      "13": 140,
      "14": 140,
    };

    return (
      <div className='labCapacity'>
        <Prompt
          message='Changes you made may not be saved.'
          when={this.state.isChange}
        />
        <ActionBar left={this.leftSection} right={this.rightSection} />
        <div className='container'>
          <br />
          <div>
            <TableGrid
              customWidth={customWidth}
              tblWidth={tblWidth}
              tblHeight={tblHeight}
              isChange={isChange}
              changeValue={this.changeValue}
              applyToAll={this.addToChange2}
              sideMenu={this.props.sideMenu}
              data={this.props.data}
              columns={this.props.columns}
              focusName={this.state.focusName}
              setFocusName={this.setFocusName}
              grid='labCapacity'
            />
          </div>
        </div>
      </div>
    );
  }
}
LabComponent.defaultProps = {
  selected: "",
  year: [],
  data: [],
  columns: [],
  isChange: false,
};
LabComponent.propTypes = {
  sideMenu: PropTypes.bool.isRequired,
  selected: PropTypes.string, // eslint-disable-line react/forbid-prop-types
  year: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  data: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  columns: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  labDataChange: PropTypes.func.isRequired,
  labYearFetch: PropTypes.func.isRequired,
  labFetch: PropTypes.func.isRequired,
  labDataRowChange: PropTypes.func.isRequired,
  labDataChange: PropTypes.func.isRequired,
  labDataUpdate: PropTypes.func.isRequired,
  isChange: PropTypes.bool,
};
export default withAITracking(reactPlugin, LabComponent);
