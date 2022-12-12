import React from 'react';
import { connect } from 'react-redux';
import { Cell } from 'fixed-data-table-2';
import PropTypes from 'prop-types';

const Option = ({
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

  let value = '';
  const columnCountryOrigin = columnKey.toLocaleLowerCase() === 'cntryoforigin';
  let originCountryValue = '';

  if (traitID === null) {
    value = data[rowIndex][columnKey] || '';
  }

  if (columnCountryOrigin) {
    if (data[rowIndex][columnKey]) {
      const current = data[rowIndex][columnKey];
      const matchCountry = countryOrigin.filter(r => r.countryCode === current);
      if (matchCountry.length) {
        originCountryValue = matchCountry[0].name; //matchCountry[0].name;
      }
    }
  }
  const { gid } = data[rowIndex];
  const { statusCode, replacedLot } = data[rowIndex];

  if (
    selected.columnKey !== undefined &&
    rowIndex === selected.index &&
    columnKey.toLocaleLowerCase() === 'newcrop' &&
    columnKey.toLocaleLowerCase() === selected.columnKey.toLocaleLowerCase()
  ) {
    return (
      <Cell className={isCellHighlighted ? 'isCell selectedRow' : 'isCell'}>
        <select
          name="newCrop"
          value={value}
          className="newSelect"
          onChange={onNewCropChange}
          onBlur={selectBlur}
          autoFocus={true} // eslint-disable-line
        >
          <option value="">select</option>
          {newcrop.map(crop => {
            const { newCropID, newCropCode } = crop;
            return <option key={newCropID}>{newCropCode}</option>;
          })}
        </select>
      </Cell>
    );
  }
  // product segment
  if (
    selected.columnKey !== undefined &&
    rowIndex === selected.index &&
    columnKey.toLocaleLowerCase() === 'prod.segment' &&
    columnKey.toLocaleLowerCase() === selected.columnKey.toLocaleLowerCase()
  ) {
    const { newCrop } = data[rowIndex] || '';

    return (
      <Cell>
        <select
          className="newSelect"
          value={value}
          onChange={onNewCropChange}
          onBlur={selectBlur}
          autoFocus={true} // eslint-disable-line
        >
          <option value="">select</option>
          {productsegment.filter(d => d.newCropCode === newCrop).map(prod => {
            const { prodSegCode } = prod;
            return <option key={prodSegCode}>{prodSegCode}</option>;
          })}
        </select>
      </Cell>
    );
  }

  if (
    selected.columnKey !== undefined &&
    rowIndex === selected.index &&
    columnCountryOrigin &&
    columnKey.toLocaleLowerCase() === selected.columnKey.toLocaleLowerCase()
  ) {
    return (
      <Cell>
        <select
          className="newSelect"
          value={value}
          onChange={onNewCropChange}
          onBlur={selectBlur}
          autoFocus={true} // eslint-disable-line
        >
          <option value="">select</option>
          {countryOrigin.map(d => {
            const { countryCode, name } = d;
            return <option key={countryCode} value={countryCode}>{name}</option>
          })}
        </select>
      </Cell>
    );
  }

  if (replacedLot) {
    return (
      <Cell
        className={isCellHighlighted ? 'isCell selectedRow' : 'isCell'}
        onClick={(event) => dClick(rowIndex, gid, columnKey, event)}
      >
        {columnCountryOrigin ? originCountryValue : value}
      </Cell>
    );
  }
  const comboConditon = statusCode !== 100;
  return (
    <Cell
      className={isCellHighlighted ? 'isCell selectedRow' : 'isCell'}
      onClick={(event) => comboConditon ? {} : dClick(rowIndex, gid, columnKey, event) }
    >
      {columnCountryOrigin ? originCountryValue : value}
    </Cell>
  );
};

Option.defaultProps = {
  columnKey: '',
  rowIndex: 0,
  traitID: null,
  newcrop: [],
  productsegment: [],
  countryOrigin: []
};
Option.propTypes = {
  columnKey: PropTypes.string,
  rowIndex: PropTypes.number,
  data: PropTypes.array, // eslint-disable-line
  traitID: PropTypes.number,
  dClick: PropTypes.func.isRequired,
  newcrop: PropTypes.array, // eslint-disable-line
  productsegment: PropTypes.array, // eslint-disable-line
  countryOrigin: PropTypes.array, // eslint-disable-line
  onNewCropChange: PropTypes.func.isRequired,
  selectBlur: PropTypes.func.isRequired,
  checkList: PropTypes.array, // eslint-disable-line
  selected: PropTypes.object // eslint-disable-line
};

const mapState = state => ({
  newcrop: state.main.newcrop,
  productsegment: state.main.productsegment,
  countryOrigin: state.main.origin
});
const mapDispatch = null;
const newObject = connect(
  mapState,
  mapDispatch
)(Option);
export { newObject as default };
