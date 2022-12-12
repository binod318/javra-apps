import React from 'react';
import { connect } from 'react-redux';
import { Cell } from 'fixed-data-table-2';

const Option = ({
  children,
  columnKey,
  rowIndex,
  data,
  traitID,
  dClick,
  selected,
  newcrop,
  productsegment,
  countryOrigin,

  onNewCropChange,
  selectBlur,
  checkList
}) => {
  let isCellHighlighted = false;
  if (checkList) isCellHighlighted = checkList.includes(rowIndex);

  // value
  let value = '';
  if (traitID === null) {
    const key = columnKey.toLocaleLowerCase();
    value = data[rowIndex][columnKey] || '' ;
  }

  const gid = data[rowIndex]['gid'];
  const statusCode = data[rowIndex]['statusCode'];
  // new cropcode
  if (
    selected.columnKey !== undefined
    && rowIndex === selected.index
    && columnKey.toLocaleLowerCase() === 'newcrop'
    && columnKey.toLocaleLowerCase() === selected.columnKey.toLocaleLowerCase()
    ) {
    return (
      <Cell className={isCellHighlighted ? 'isCell selectedRow' : 'isCell'}>
        <select
          name="newCrop"
          value={value}
          className="newSelect"
          onChange={onNewCropChange}
          onBlur={selectBlur}
          autoFocus={true}
        >
          <option value="">Select</option>
          {newcrop.map(crop =>(
            <option key={crop.newCropID}>
              {crop.newCropCode}
            </option>
          ))}
        </select>
      </Cell>
    );
  }
  // product segment
  if (
    selected.columnKey !== undefined
    && rowIndex === selected.index
    && columnKey.toLocaleLowerCase() === 'prod.segment'
    && columnKey.toLocaleLowerCase() === selected.columnKey.toLocaleLowerCase()
    ) {
      const subList = data[rowIndex]['newCrop'] || '';

      return (
        <Cell className={isCellHighlighted ? 'isCell selectedRow' : 'isCell'}>
          <select
            className="newSelect"
            value={value}
            onChange={onNewCropChange}
            onBlur={selectBlur}
            autoFocus={true}
          >
            <option value="">Select</option>
            {productsegment.filter(d => d.newCropCode === subList).map(prod =>(
              <option key={prod.prodSegCode}>
                {prod.prodSegCode}
              </option>
            ))}
          </select>
        </Cell>
      );
    }



  return statusCode !== 100
    ? (
      <Cell className="isCell">{value}</Cell>
    ) : (
    <Cell
      className={isCellHighlighted ? 'isCell selectedRow' : 'isCell'}
      onDoubleClick={() => dClick(rowIndex, gid, columnKey)}
    >
      {value}
    </Cell>
  );
};

const mapState = state => ({
  newcrop: state.main.newcrop,
  productsegment: state.main.productsegment,
  countryOrigin: state.main.origin
});
export default connect(mapState, null)(Option);
