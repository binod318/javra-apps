import React from 'react';
import { Cell } from 'fixed-data-table-2';
import PropTypes from 'prop-types';

const Data = ({ columnKey, rowIndex, data, traitID, refColumn }) => {

  let styleValue = 0;

  if (refColumn !== null) {
    styleValue = data[rowIndex][refColumn];
  }
  let value = data[rowIndex][columnKey];
  if (traitID !== null) {
    value = data[rowIndex][traitID];
  }

  const styValue = parseInt(styleValue, 2);
  return (
    <div className={styValue === 1 ? 'cellOption1' : ''}>
      <Cell title={value}>{value}</Cell>
    </div>
  );
};

Data.defaultProps = {
  columnKey: '',
  traitID: null
};
Data.propTypes = {
  columnKey: PropTypes.string,
  rowIndex: PropTypes.number.isRequired,
  data: PropTypes.array, // eslint-disable-line
  traitID: PropTypes.oneOfType([PropTypes.number, PropTypes.object]), // eslint-disabel-line
  refColumn: PropTypes.number.isRequired
};
export { Data as default };
