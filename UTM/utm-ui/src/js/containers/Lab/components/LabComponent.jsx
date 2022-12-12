import React from 'react';
import PropTypes from 'prop-types';
import { Prompt } from 'react-router-dom';

import TableLab from './TableLab';
import { getDim } from '../../../helpers/helper';

class LabComponent extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      data: props.data,
      isChange: false,
      tblWidth: 900,
      tblHeight: 600,
      changed: []
    };
    const dd = new Date();
    this.currentYear = dd.getFullYear();
    this.startYear = 2015;
    this.endYear = 2030;
    props.pageTitle();
  }

  componentDidMount() {
    window.addEventListener('beforeunload', this.handleWindowClose);
    window.addEventListener('resize', this.updateDimensions);
    this.updateDimensions();
    this.props.labFetch(this.currentYear);
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.data) {
      this.setState({ data: nextProps.data });
      this.updateDimensions();
    }
  }

  componentWillUnmount() {
    window.removeEventListener('beforeunload', this.handleWindowClose);
    window.removeEventListener('resize', this.updateDimensions);
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
      e.returnValue = 'blocked';
    }
  };

  changeYear = e => {
    this.currentYear = e.target.value;
    this.props.labFetch(e.target.value);
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
    this.props.labDataUpdate(this.state.changed, this.currentYear);
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
                defaultValue={this.currentYear}
              >
                {yearList}
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
LabComponent.defaultProps = {
  data: [],
  isChange: false
};
LabComponent.propTypes = {
  data: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  pageTitle: PropTypes.func.isRequired,
  labFetch: PropTypes.func.isRequired,
  labDataRowChange: PropTypes.func.isRequired,
  labDataChange: PropTypes.func.isRequired,
  labDataUpdate: PropTypes.func.isRequired,
  // add to remove eslint error
  // 2019 june 13
  isChange: PropTypes.bool
};
export default LabComponent;
