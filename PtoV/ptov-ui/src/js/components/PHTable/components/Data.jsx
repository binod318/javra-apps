import React from 'react';
import { Cell } from 'fixed-data-table-2';
import PropTypes from 'prop-types';
import uuid from 'uuid/v1';

const Data = ({
  columnKey,
  rowIndex,
  data,
  refColumn,
  checkList,
  tableType,
  opAsParent,
  opasparentStore,
  fileStatus,
  without,
  isFilter
}) => {
  if (rowIndex < 0) return null;
  let isCellHighlighted = false;
  if (checkList) isCellHighlighted = checkList.includes(rowIndex);
  let cellStyle = 'isCell';

  let styleValue = 0;
  if (data === undefined) {
    return <Cell />;
  }
  if (refColumn !== null && tableType !== 'active') {
    styleValue = data[rowIndex][refColumn] || 0;
  }

  if (columnKey == 'opAsParent') {
    if (data[rowIndex][columnKey]) {
      cellStyle = columnKey === 'gid' ? `${cellStyle} blockRow` : cellStyle;
      cellStyle = isCellHighlighted ? `${cellStyle} selectedRow` : cellStyle;

      const opAsParentID = data[rowIndex]['varietyID'];
      const compValue = opasparentStore[rowIndex] && opasparentStore[rowIndex].checked;
      const checkValue = compValue ?  opasparentStore[rowIndex].checked : false;

      const checkBox = fileStatus !== 100
        ? <div className="inCell disabled"><i className='icon icon-check-empty' /></div>
        : (
          <label
            htmlFor={columnKey+rowIndex}
            className={checkValue ? 'inCell active' : 'inCell'}
          >
            <i className={checkValue ? 'icon icon-ok-squared' : 'icon icon-check-empty'} />
            <input
              id={columnKey+rowIndex}
              type="checkbox"
              name="filterStatus"
              onChange={() => opAsParent(opAsParentID)}
              checked={checkValue}
              style={{visibility:'hidden', position:'absolute'}}
            />
          </label>
        );
      return (
        <Cell className={cellStyle} style={{textAlign:'center'}}>
            {checkBox}
        </Cell>
      );
    }
    return (
      <Cell className={isCellHighlighted ? 'isCell selectedRow' : 'isCell'} />
    );
  }

  const textValue = data[rowIndex][columnKey];
  const value = typeof textValue === 'boolean' ? '' : textValue;

  let { transferType } = data[rowIndex];
  if (transferType) {
    transferType = transferType.toLocaleLowerCase();
  }

  let icon = '';
  const { raciprocated } = data[rowIndex];

  if (columnKey.toLocaleLowerCase() === 'gid') {
    switch (transferType) {
      case 'female':
        icon = <i className="icon icon-female female" title="Female" />;
        break;
      case 'male':
        icon = <i className="icon icon-male male" title="Male" />;
        break;
      case 'maintainer':

        icon = (
          <i
            className={
              'icon icon-male maintainer '+ (without ? 'maintainerFlat' : '')
            }
            title="Maintainer"
          />
        );
        break;
      default:
    }

    const { parentNode } = data[rowIndex];
    if (parentNode >= 0) {

      const rightArrow = <i className="icon icon-angle-right" />;
      const empty = [];

      if (parentNode === 0) {
        icon = <i className="icon icon-angle-right" />;
      } else {
        for (let i = 1; i <= parentNode; i += 1) {
          empty.push(<span className="empty-icon" />);
        }
        icon = (
          <span key={uuid()}>
            {empty} {rightArrow}
          </span>
        );
      }
    }
    if (parentNode === null) {
      icon = <span className="empty-icon" />;
    }
  }
  const icon2 =
    raciprocated && columnKey === 'gid' ? (
      <i className="icon icon-shuffle reciprocal" title="" />
    ) : null;

  // REPLACE LOAT MOD SCREEN CELL BORDER COLOR
  const { replacedLot } = data[rowIndex];
  if (
    data[rowIndex].statusCode !== 100 &&
    tableType === 'active' &&
    !replacedLot
  ) {
    cellStyle =
      columnKey === 'gid'
        ? `${cellStyle} ${columnKey} blockRow`
        : `${cellStyle} ${columnKey}`;
    if (columnKey === 'id') {
      const { lvl } = data[rowIndex];
      if (lvl < 0) {
        cellStyle = `${cellStyle} ped-parent`;
      } else if (lvl > 0) {
        cellStyle = `${cellStyle} ped-child`;
      } else {
        cellStyle = `${cellStyle} ped-self`;
      }
    }
    cellStyle = isCellHighlighted ? `${cellStyle} selectedRow` : cellStyle;

    return (
      <Cell title={value} className={cellStyle}>
        {icon}
        {value}{' '}{icon2}
      </Cell>
    );
  }
  if (replacedLot) {
    cellStyle = columnKey === 'gid' ? `${cellStyle} replacedRow` : cellStyle;
    return (
      <Cell
        title={value}
        className={isCellHighlighted ? `${cellStyle} selectedRow` : cellStyle}
      >
        {icon}
        {value}
        {icon2}
      </Cell>
    );
  }

  if (tableType === 'active') {
    return (
      <Cell
        title={value}
        className={isCellHighlighted ? 'isCell selectedRow' : 'isCell'}
      >
        {icon}
        {value}
        {icon2}
      </Cell>
    );
  }

  return (
    <div className={styleValue === 1 ? 'isCell cellOption1' : 'isCell'}>
      <Cell title={value}>
        {icon}
        {value}
        {icon2}
      </Cell>
    </div>
  );
};

Data.defaultProps = {
  columnKey: '',
  refColumn: null,
  tableType: '1',
  rowIndex: -1
};
Data.propTypes = {
  columnKey: PropTypes.string,
  rowIndex: PropTypes.number,
  data: PropTypes.array, // eslint-disable-line
  refColumn: PropTypes.oneOfType([PropTypes.string, PropTypes.object]),
  checkList: PropTypes.array, // eslint-disable-line
  tableType: PropTypes.string
};
export default Data;
