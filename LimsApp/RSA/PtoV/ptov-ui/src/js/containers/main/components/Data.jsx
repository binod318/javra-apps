import React from 'react';
import { Cell } from 'fixed-data-table-2';
import PropTypes from 'prop-types';

const Data = ({ columnKey, rowIndex, data, checkList }) => {
  // children, traitID
  let isCellHighlighted = false;
  if (checkList) isCellHighlighted = checkList.includes(rowIndex);
  let cellStyle = 'isCell';

  let icon = '';
  let { transferType } = data[rowIndex];

  if (columnKey === 'gid') {
    transferType = transferType.toLocaleLowerCase();
    switch (transferType) {
      case 'female':
        icon = <i className="icon icon-female female" title="Female" />;
        break;
      case 'male':
        icon = <i className="icon icon-male male" title="Male" />;
        break;
      case 'maintainer':
        icon = <i className="icon icon-tree -2 icon-leaf maintainer" title="Maintainer" />;
        break;
      default:
    }
  }

  // value
  const value = data[rowIndex][columnKey];

  if (data[rowIndex].statusCode !== 100) {
    cellStyle = columnKey === 'gid' ? `${cellStyle} blockRow` : cellStyle;
    return (
      <Cell title={value} className={cellStyle}>
        {icon}
        {value}
      </Cell>
    );
  }

  return (
    <Cell
      title={value}
      className={isCellHighlighted ? 'isCell selectedRow' : 'isCell'}
    >
      {icon}
      {value}
    </Cell>
  );
};

Data.defaultProps = {
  columnKey: '',
  rowIndex: 0
};
Data.propTypes = {
  columnKey: PropTypes.string,
  rowIndex: PropTypes.number,
  data: PropTypes.array, // eslint-disable-line
  checkList: PropTypes.array, // eslint-disable-line
};
export default Data;
