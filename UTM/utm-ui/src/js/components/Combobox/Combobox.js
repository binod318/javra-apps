import React from 'react';
import PropTypes from 'prop-types';

const DropDown = ({
  label,
  options,
  change,
  disabled,
  value = null,
  name,
  listName,
  listCode
}) => {
  let selected = '';
  let drawOption = '';
  if (listName !== '' && listCode !== '') {
    drawOption = options.map(d => (
      <option value={d[listCode]} key={d[listCode]}>
        {d[listName]}
      </option>
    ));
  } else {
    switch (label) {
      case 'Material Type':
        drawOption = options.map(d => {
          if (d.selected) {
            selected = d.materialTypeID;
          }
          return (
            <option key={d.materialTypeID} value={d.materialTypeID}>
              {d.materialTypeCode} - {d.materialTypeDescription}
            </option>
          );
        });
        break;
      case 'Method':
          drawOption = options.map(d => {
            if (d.selected) {
              selected = d.testProtocolID;
            }
            return (
              <option key={d.testProtocolID} value={d.testProtocolID}>
                {d.testProtocolName}
              </option>
            );
          });
          break;
      case 'Lab Location':
        drawOption = options.map(d => {
          if (d.selected) {
            selected = d.siteID;
          }
          return (
            <option key={d.siteID} value={d.siteID}>
              {d.siteName}
            </option>
          );
        });
        break;
      case 'Material State':
        drawOption = options.map(d => {
          if (d.selected) {
            selected = d.materialStateID;
          }
          return (
            <option key={d.materialStateID} value={d.materialStateID}>
              {d.materialStateCode} - {d.materialStateDescription}
            </option>
          );
        });
        break;
      case 'Container Type':
        drawOption = options.map(d => {
          if (d.selected) {
            selected = d.containerTypeID;
          }
          return (
            <option key={d.containerTypeID} value={d.containerTypeID}>
              {d.containerTypeCode} - {d.containerTypeName}
            </option>
          );
        });
        break;
      case 'Test type':
        drawOption = options.map(d => (
          <option value={d.testTypeID} key={d.testTypeID}>
            {d.testTypeName}
          </option>
        ));
        break;
      case 'Slot':
        drawOption = options.map(d => (
          <option value={d.slotID} key={d.slotID}>
            {d.slotName}
          </option>
        ));
        break;
      case 'Site Location':
        drawOption = options.map(d => {
          if (d.selected) {
            selected = d.siteID;
          }
          return (
            <option key={d.siteID} value={d.siteID}>
              {d.siteName}
            </option>
          );
        });
        break;
      case 'Sample Type':
        drawOption = options.map(d => {
          if (d.selected) {
            selected = d.sampleTypeCode;
          }
          return (
            <option key={d.sampleTypeCode} value={d.sampleTypeCode}>
              {d.sampleTypeName}
            </option>
          );
        });
        break;
      case 'Project List':
        drawOption = [
          <option value="1" key="1">
            test 1
          </option>
        ];
        // options.map(d => (
        //   <option value={d.slotID} key={d.slotID}>
        //     {d.slotName}
        //   </option>
        // ));
        break;
      default:
    }
  }

  return (
    <div>
      <label>{label}</label> {/*eslint-disable-line*/}
      <select
        name={name}
        disabled={disabled}
        onChange={change}
        value={value === null ? selected : value}
      >
        <option>Select</option>
        {drawOption}
      </select>
    </div>
  );
};
DropDown.defaultProps = {
  name: '',
  listName: '',
  listCode: '',
  value: null,
  disabled: false
};
DropDown.propTypes = {
  name: PropTypes.string,
  listName: PropTypes.string,
  listCode: PropTypes.string,
  label: PropTypes.string.isRequired,
  change: PropTypes.func.isRequired,
  options: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  value: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  disabled: PropTypes.bool
};
export default DropDown;
