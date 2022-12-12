import React, { useState, useEffect } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';

import './rdtPrint.scss';

const ManageRDTprint = props => {
  const {
    status,
    testID,
    // statusCode,
    display,
    importLevel,
    materialStateList,
    print,
    close,
    data,
    column
  } = props;

  // PLT or LIST
  const [materialStatus, setMaterialStatus] = useState('');
  const [checked, setChecked] = useState([]);

  const list = [];
  column.map(col => {
    const { traitID, columnLabel } = col;

    if (traitID && traitID.toString().substring(0, 2) === 'D_') {
      const map = traitID.split('_');
      const lowTraitID = traitID.toLowerCase();
      if (data[lowTraitID] !== 0) {
        list.push({
          columnLabel,
          determinationID: map[1]
        });
      }
    }
    return null;
  });
  useEffect(() => {
    setChecked([]);
    setMaterialStatus('');
  }, [testID, display, data.materialID]);

  if (!display && data && data.materialID === undefined) return null;
  function materialStateChange(e) {
    setMaterialStatus(e.target.value);
  }
  const localPrint = () => {
    if (data !== 0) {
      const materialDeterminations = checked.map(determinationID => ({
        materialID: data.materialID,
        determinationID
      }));
      print({ testID, materialStatus: [], materialDeterminations });
      return null;
    }
    print({ testID, materialStatus });
    return null;
  };

  const localClose = () => {
    close();
  };

  function onChange(e) {
    const { name } = e.target;

    if (checked.indexOf(name) !== -1) {
      const index = checked.filter(c => c !== name);
      setChecked(index);
    } else {
      setChecked([...checked, name]);
    }
  }

  return (
    <div className="remarksWrap">
      <div className="remarksContent">
        <div className="remarksTitle">
          <i className="demo-icon icon-print info" />
          <span>
            Print Sticker
            {importLevel.toLowerCase() !== 'list' &&
              ` (Plant Name: ${data['plant name']})`}
            {importLevel.toLowerCase() === 'list' &&
              data.gid !== undefined &&
              ` (GID: ${data.gid})`}
          </span>
          <i
            role="presentation"
            className="demo-icon icon-cancel close"
            onClick={localClose}
            title="Close"
          />
        </div>
        <div className="remarksBody rdtprintform">
          {data.gid === undefined && importLevel.toLowerCase() === 'list' && (
            <select value={materialStatus} onChange={materialStateChange}>
              <option value="">All</option>
              {materialStateList.map(({ code, name }) => (
                <option key={code} value={code}>
                  {name}
                </option>
              ))}
            </select>
          )}
          {data.materialID &&
            list.map(ll => {
              const { columnLabel, determinationID } = ll;
              const isSelected = checked.includes(determinationID);
              const lbl = columnLabel.slice(0, columnLabel.indexOf(' ')) || '';
              return (
                <div className="marks" key={determinationID}>
                  <input
                    name={`${determinationID}`}
                    id={`${determinationID}`}
                    type="checkbox"
                    checked={isSelected}
                    onChange={onChange}
                  />
                  <label htmlFor={`${determinationID}`}>{lbl}</label> {/*eslint-disable-line*/}
                </div>
              );
            })}
        </div>
        <div className="remarksFooter">
          <button
            onClick={localPrint}
            disabled={data.materialID ? checked.length === 0 : status > 0}
            title="Print"
          >
            Print
          </button>
        </div>
      </div>
    </div>
  );
};

ManageRDTprint.defaultProps = {
  testID: '',
  // statusCode: '',
  column: [],
  materialStateList: []
};
ManageRDTprint.propTypes = {
  column: PropTypes.array, // eslint-disable-line
  data: PropTypes.object, // eslint-disable-line
  importLevel: PropTypes.string.isRequired,
  status: PropTypes.number, //.isRequired
  display: PropTypes.bool.isRequired,
  close: PropTypes.func.isRequired,
  print: PropTypes.func.isRequired,
  testID: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  // statusCode: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  // importLevel: PropTypes.string.isRequired,
  materialStateList: PropTypes.array // eslint-disable-line
};
const mapState = state => ({
  status: state.loader,
  display: state.assignMarker.rdtPrint,
  data: state.assignMarker.rdtPrintData,
  column: state.assignMarker.materials.columns,
  testID: state.rootTestID.testID,
  importLevel: state.rootTestID.importLevel,
  statusCode: state.rootTestID.statusCode,
  materialStateList: state.assignMarker.materialStateRDT
});
const mapDispatch = dispatch => ({
  close: () => dispatch({ type: 'RDT_PRINT_HIDE' }),
  print: obj => dispatch({ type: 'POST_RDT_PRINT', ...obj })
});
export default connect(
  mapState,
  mapDispatch
)(ManageRDTprint);
