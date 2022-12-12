import React from "react";
import PropTypes from "prop-types";
import { Prompt } from "react-router-dom";

import TableLab from "./TableLab";
import { getDim } from "../../../helpers/helper";
import { localStorageService } from "../../../services/local-storage.service"

class LDLabComponent extends React.Component {
  constructor(props) {
    super(props);
    
    const dd = new Date();
    this.currentYear = dd.getFullYear();
    this.startYear = 2015;
    this.endYear = 2030;

    this.state = {
      data: props.data,
      isChange: false,
      tblWidth: 900,
      tblHeight: 600,
      changed: [],
      siteLocation: 0,
      year: this.currentYear
    };

    props.pageTitle();
  }

  componentDidMount() {
    window.addEventListener("beforeunload", this.handleWindowClose);
    window.addEventListener("resize", this.updateDimensions);
    this.updateDimensions();
    this.props.locationFetch();
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.data) {
      this.setState({ data: nextProps.data });
      this.updateDimensions();
    }

    if (nextProps.location != this.props.location && nextProps.location.length > 0) {
      //trigger data fetch
      this.initiateFetch(nextProps.location);
    }
  }

  componentWillUnmount() {
    window.removeEventListener("beforeunload", this.handleWindowClose);
    window.removeEventListener("resize", this.updateDimensions);
  }

  initiateFetch(locationList) {
    let location = localStorageService.get("siteLocation");
    if(location == undefined)
      location = locationList[0].siteID;

    this.setState({siteLocation: location});
    this.props.labFetch(this.state.year, location);
  }

  updateDimensions = () => {
    const dim = getDim();
    this.setState({
      tblWidth: dim.width,
      tblHeight: dim.height
    });
  };

  handleWindowClose = e => {
    if (this.props.isChange) {
      e.returnValue = "blocked";
    }
  };

  changeYear = e => {
    this.currentYear = e.target.value;

    this.setState({
      year: this.currentYear
    })

    if(this.state.siteLocation > 0)
      this.props.labFetch(this.currentYear, this.state.siteLocation);
  };

  changeLocation = e => {
    const siteLocation = e.target.value;

    //store location on local storage
    localStorageService.set("siteLocation", siteLocation);
    this.setState({ siteLocation });

    this.props.labFetch(this.state.year, siteLocation);
  };

  addToChange2 = (k, v) => {
    const { changed, data } = this.state;

    if (changed.length <= 0) {
      const obj = data.map(d => ({
        periodID: d.periodID,
        testProtocolID: k,
        value: v
      }));

      this.setState({ isChange: true, changed: obj });
    } else {
      const obj2 = changed.filter(d => d.testProtocolID !== k);
      data.map(d => {
        obj2.push({
          periodID: d.periodID,
          testProtocolID: k,
          value: v
        });
        return null;
      });
      this.setState({ isChange: true, changed: obj2 });
    }
    this.props.labDataRowChange(k, v);
  };

  addToChange = (p, k, v) => {
    const { changed } = this.state;
    const obj = [];

    if (changed.length <= 0) {
      obj.push({
        periodID: p,
        testProtocolID: k,
        value: v
      });
      this.setState({ isChange: true, changed: obj });
    } else {
      const check = changed.filter(
        d => d.periodID === p && d.testProtocolID === k
      );
      if (check.length) {
        const newObj = changed.map(d => {
          if (d.periodID === p && d.testProtocolID === k) {
            return {
              periodID: p,
              testProtocolID: k,
              value: v
            };
          }
          return d;
        });
        this.setState({ isChange: true, changed: newObj });
      } else {
        obj.push.apply(changed, [
          {
            periodID: p,
            testProtocolID: k,
            value: v
          }
        ]);
      }
    }
  };

  changeValue = (i, k, v, p) => {
    this.props.labDataChange(i, k, v);
    this.addToChange(p, k, v);
  };

  saveChange = () => {
    this.props.labDataUpdate(this.state.siteLocation, this.state.changed, this.currentYear);
    this.setState({
      isChange: false,
      changed: []
    });
  };

  render() {
    const { isChange, tblWidth, tblHeight } = this.state;
    // applyShow, keyName
    // startYear
    // endYear
    const yearList = [];
    for (let i = this.startYear; i <= this.endYear; i += 1) {
      if (this.currentYear !== i) {
        yearList.push(
          <option key={i} value={i}>
            {i}
          </option>
        );
      } else {
        yearList.push(
          <option key={i} value={i}>
            {i}
          </option>
        );
      }
    }
    return (
      <div className="labCapacity">
        <Prompt
          message="Changes you made may not be saved."
          when={this.state.isChange}
        />
        <section className="page-action">
          <div className="left">
            <div className="form-e">
              <label htmlFor="year">Year</label>
              <select
                id="year"
                name="year"
                onChange={this.changeYear}
                value={this.state.year}
              >
                {yearList}
              </select>
            </div>
            <div className="form-e">
              <label htmlFor="location">Lab Location</label>{" "}
              {/* eslint-disable-line */}
              <select
                id="location"
                name="location"
                onChange={this.changeLocation}
                value={this.state.siteLocation}
                className="w-200"
              >
                {this.props.location.map(location => {
                  const {
                    siteID,
                    siteName
                  } = location;
                  return (
                    <option
                      key={`${siteID}`}
                      value={siteID}
                    >
                      {siteName}
                    </option>
                  );
                })}
              </select>
            </div>
          </div>
          <div className="right">
            <button
              className="with-i"
              disabled={!isChange}
              onClick={this.saveChange}
            >
              <i className="icon icon-floppy-1" />
              Save
            </button>
          </div>
        </section>

        <div className="container">
          <br />
          <div>
            <TableLab
              tblWidth={tblWidth}
              tblHeight={tblHeight}
              isChange={isChange}
              changeValue={this.changeValue}
              applyToAll={this.addToChange2}
            />
          </div>
        </div>
      </div>
    );
  }
}
LDLabComponent.defaultProps = {
  data: [],
  isChange: false,
  location: []
};
LDLabComponent.propTypes = {
  data: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  location: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  pageTitle: PropTypes.func.isRequired,
  labFetch: PropTypes.func.isRequired,
  locationFetch: PropTypes.func.isRequired,
  labDataRowChange: PropTypes.func.isRequired,
  labDataChange: PropTypes.func.isRequired,
  labDataUpdate: PropTypes.func.isRequired,
  // add to remove eslint error
  // 2019 june 13
  isChange: PropTypes.bool
};
export default LDLabComponent;
