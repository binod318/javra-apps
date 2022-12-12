import React, { Component } from 'react';
import autoBind from 'auto-bind';
import { Cell } from 'fixed-data-table-2';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

class DonorCell extends Component {
  constructor(props) {
    super(props);
    this.state = { name: '', value: '', focus: false }; // startDate: null
    autoBind(this);
  }

  getValue = () => {
    const { rowIndex, data, donerMaps, columnKey } = this.props;
    const { materialID } = data[rowIndex];
    if (donerMaps[`${materialID}-doner`]) {
      if (columnKey === 'DH0Net') {
        return donerMaps[`${materialID}-doner`].dH0Net;
      }
      if (columnKey === 'Requested') {
        return donerMaps[`${materialID}-doner`].requested;
      }
      if (columnKey === 'Transplant') {
        return donerMaps[`${materialID}-doner`].transplant;
      }
      if (columnKey === 'ToBeSown') {
        return donerMaps[`${materialID}-doner`].toBeSown;
      }
      if (columnKey === 'ProjectCode') {
        return donerMaps[`${materialID}-doner`].projectCode;
      }
      if (columnKey === 'ProcessID') {
        return donerMaps[`${materialID}-doner`].processID;
      }
      if (columnKey === 'LabLocationID') {
        return donerMaps[`${materialID}-doner`].labLocationID;
      }
      if (columnKey === 'StartMaterialID') {
        return donerMaps[`${materialID}-doner`].startMaterialID;
      }
      if (columnKey === 'TypeID') {
        return donerMaps[`${materialID}-doner`].typeID;
      }
      if (columnKey === 'Net') {
        return donerMaps[`${materialID}-doner`].net;
      }
      if (columnKey === 'Remarks') {
        return donerMaps[`${materialID}-doner`].remarks;
      }
      if (columnKey === 'DH1ReturnDate') {
        return donerMaps[`${materialID}-doner`].dH1ReturnDate;
      }
      if (columnKey === 'RequestedDate') {
        return donerMaps[`${materialID}-doner`].requestedDate;
      }
      if (columnKey === 'DonorNumber') {
        return donerMaps[`${materialID}-doner`].donorNumber;
      }
    }
    return '';
  };

  handleChange(e) {
    const { rowIndex, data } = this.props;
    const { materialID } = data[rowIndex];

    const {
      target: { name, value }
    } = e;
    if (name === 'projectCode') {
      this.props.donerChange(materialID, name, value);
      this.setState({ value });
      return null;
    }
    if (name === 'remarks') {
      this.props.donerChange(materialID, name, value);
      this.setState({ value });
      return null;
    }
    if (name === 'donorNumber') {
      this.props.donerChange(materialID, name, value);
      this.setState({ value });
      return null;
    }
    if (name === 'dH1ReturnDate') {
      this.props.donerChange(materialID, name, value);
      this.setState({ value });
      return null;
    }
    if (name === 'requestedDate') {
      this.props.donerChange(materialID, name, value);
      // this.setState({ [name]: value });
      this.setState({ value });
      return null;
    }
    if (value * 1 && value * 1 >= 0) {
      this.props.donerChange(materialID, name, value * 1);
      this.setState({ value: value * 1 });
    } else if (value * 1 === 0) {
      this.props.donerChange(materialID, name, '');
      this.setState({ value: '' });
    } else {
      const nvalue = this.getValue();
      // this.props.donerChange(materialID, name, nvalue);
      this.setState({ value: nvalue });
    }
    // alert('handleChange');
    return null;
  }
  handleDateChange = () => {
  };

  blur = () => {
    setTimeout(() => {
      this.setState({ focus: false });
    }, 500);
  };
  focus = e => {
    const { target } = e;
    const { name } = target;
    if (name === 'remarks') return null;
    // if (name === 'dH1ReturnDate') return null;
    // const { name: nn, rowIndex } = this.props;
    // this.props.setFocusTarget(`${nn}_${rowIndex}`);
    this.setState({
      name,
      focus: true,
      value: this.getValue()
    });
    return null;
  };

  applyToAll = () => {
    // alert('apply');
    const { rowIndex, data } = this.props;
    const { materialID } = data[rowIndex];
    const { name, value } = this.state;
    // const { target: { value } } = e;
    if (name === 'dH1ReturnDate') {
      this.props.donerAllChange(materialID, name, value);
      this.setState({ [name]: value });
      return null;
    }
    if (name === 'requestedDate') {
      this.props.donerAllChange(materialID, name, value);
      this.setState({ [name]: value });
      return null;
    }

    if (value * 1 && value * 1 >= 0)
      this.props.donerAllChange(materialID, name, value * 1);
    else if (value * 1 === 0)
      this.props.donerAllChange(materialID, name, value);
    else this.props.donerAllChange(materialID, name, this.getValue());

    return null;
  };

  render() {
    const { rowIndex, columnKey, name } = this.props;
    const { focus } = this.state;
    const value = this.getValue();
    if (columnKey === 'ProjectCode') {
      const { projects } = this.props;
      return (
        <Cell className="tableInputSampleNr" onBlur={this.blur}>
          <div style={{ display: 'flex' }}>
            <select
              tabIndex={rowIndex + 1}
              name={name}
              value={value}
              onChange={this.handleChange}
              onFocus={this.focus}
            >
              <option value="" />
              {projects.map(p => (
                <option key={p.code} value={p.program}>
                  {p.program}
                </option>
              ))}
            </select>
            {focus && (
              <button tabIndex={-1} onClick={this.applyToAll}>
                To all
              </button>
            )}
          </div>
        </Cell>
      );
    }
    if (columnKey === 'ProcessID') {
      const { process } = this.props;
      return (
        <Cell className="tableInputSampleNr" onBlur={this.blur}>
          <div style={{ display: 'flex' }}>
            <select
              tabIndex={rowIndex + 1}
              name={name}
              value={value}
              onChange={this.handleChange}
              onFocus={this.focus}
            >
              <option value="" />
              {process
                .filter(x => x.active)
                .map(p => (
                  <option key={p.processID} value={p.processID}>
                    {p.processName}
                  </option>
                ))}
            </select>
            {focus && (
              <button tabIndex={-1} onClick={this.applyToAll}>
                To all
              </button>
            )}
          </div>
        </Cell>
      );
    }

    if (columnKey === 'LabLocationID') {
      const { location } = this.props;

      return (
        <Cell className="tableInputSampleNr" onBlur={this.blur}>
          <div style={{ display: 'flex' }}>
            <select
              tabIndex={rowIndex + 1}
              name={name}
              value={value}
              onChange={this.handleChange}
              onFocus={this.focus}
            >
              <option value="" />
              {location
                .filter(x => x.active)
                .map(l => (
                  <option key={l.labLocationID} value={l.labLocationID}>
                    {l.labLocationName}
                  </option>
                ))}
            </select>
            {focus && (
              <button tabIndex={-1} onClick={this.applyToAll}>
                To all
              </button>
            )}
          </div>
        </Cell>
      );
    }

    if (columnKey === 'StartMaterialID') {
      const { startMaterial } = this.props;

      return (
        <Cell className="tableInputSampleNr" onBlur={this.blur}>
          <div style={{ display: 'flex' }}>
            <select
              tabIndex={rowIndex + 1}
              name={name}
              value={value}
              onChange={this.handleChange}
              onFocus={this.focus}
            >
              <option value="" />
              {startMaterial
                .filter(x => x.active)
                .map(l => (
                  <option key={l.startMaterialID} value={l.startMaterialID}>
                    {l.startMaterialName}
                  </option>
                ))}
            </select>
            {focus && (
              <button tabIndex={-1} onClick={this.applyToAll}>
                To all
              </button>
            )}
          </div>
        </Cell>
      );
    }

    if (columnKey === 'TypeID') {
      const { typeCT } = this.props;

      return (
        <Cell className="tableInputSampleNr" onBlur={this.blur}>
          <div style={{ display: 'flex' }}>
            <select
              tabIndex={rowIndex + 1}
              name={name}
              value={value}
              onChange={this.handleChange}
              onFocus={this.focus}
            >
              <option value="" />
              {typeCT
                .filter(x => x.active)
                .map(l => (
                  <option key={l.typeID} value={l.typeID}>
                    {l.typeName}
                  </option>
                ))}
            </select>
            {focus && (
              <button tabIndex={-1} onClick={this.applyToAll}>
                To all
              </button>
            )}
          </div>
        </Cell>
      );
    }

    if (columnKey === 'DH1ReturnDate' || columnKey === 'RequestedDate') {
      // return <input type="text" placeholder="hi" value="" />;
      return (
        <Cell className="tableInputSampleNr" onBlur={this.blur}>
          <div style={{ display: 'flex' }}>
            {/* <DatePicker
              dateFormat="DD/MM/YYYY"
              popoverAttachment="bottom right"
              popoverTargetAttachment="top right"
              selected={moment(new Date())}
              onChange={() => {}}
              display
            /> */}
            <input
              tabIndex={rowIndex + 1}
              name={name}
              key={`${rowIndex}${columnKey}`}
              type="text"
              value={value}
              onChange={this.handleChange}
              onFocus={this.focus}
              placeholder="dd/mm/yyyy"
            />
            {focus && (
              <button tabIndex={-1} onClick={this.applyToAll}>
                To all
              </button>
            )}
          </div>
        </Cell>
      );
    }
    return (
      <Cell className="tableInputSampleNr" onBlur={this.blur}>
        {this.props.setFocusTarget}
        <div style={{ display: 'flex' }}>
          <input
            tabIndex={rowIndex + 1}
            name={name}
            key={`${rowIndex}${columnKey}`}
            type="text"
            value={value}
            onChange={this.handleChange}
            onFocus={this.focus}
          />
          {focus && (
            <button tabIndex={-1} onClick={this.applyToAll}>
              To all
            </button>
          )}
        </div>
      </Cell>
    );
  }
}
/*
<i
  className="icon icon-plus-squared"
  tabIndex="0"
  role="button"
  onKeyPress={() => {}}
  onClick={this.applyToAll}
  style={{ fontSize: '20px' }}
  title="Apply to all"
/>
 */
// donerInfoChange

DonorCell.defaultProps = {
  data: [],
  donerMaps: [],
  projects: [],
  process: [],
  location: [],
  startMaterial: [],
  typeCT: []
};
DonorCell.propTypes = {
  setFocusTarget: PropTypes.string.isRequired,
  donerChange: PropTypes.func.isRequired,
  donerAllChange: PropTypes.func.isRequired,

  rowIndex: PropTypes.number.isRequired,
  columnKey: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,

  data: PropTypes.array, // eslint-disable-line
  donerMaps: PropTypes.oneOfType([PropTypes.object, PropTypes.array]), // eslint-disable-line
  projects: PropTypes.array, // eslint-disable-line
  process: PropTypes.array, // eslint-disable-line
  location: PropTypes.array, // eslint-disable-line
  startMaterial: PropTypes.array, // eslint-disable-line
  typeCT: PropTypes.array // eslint-disable-line
};

const mapDispatch = dispatch => ({
  donerChange: (materialID, name, value) =>
    dispatch({ type: 'DONER_INFO_CHANGE', materialID, name, value }),
  donerAllChange: (materialID, name, value) =>
    dispatch({ type: 'DONER_ALL_CHANGE', materialID, name, value })
});
export default connect(
  null,
  mapDispatch
)(DonorCell);
