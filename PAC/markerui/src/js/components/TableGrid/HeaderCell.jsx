import React, { Fragment } from "react";
import PropTypes from "prop-types";
import { Cell } from "fixed-data-table-2";

const HeaderCell = (props) => {
  const { keyValue, view, sort, filter, sortFunc, filterFunc, activeSorting } = props;
  let n = [];

  if (view && view.includes("Wk")) {
    n.push(<span key='first'>{view.slice(0, 4)}</span>);
    n.push(<span key='second'>{view.slice(4)}</span>);
  }
  // for decluster table
  // the column info as extra data isExtraTraitMarker
  /// if it's set / true the column header wil lbe marked different colored (green here);
  const hasExtraTraitMarker =
    props.isExtraTraitMarker !== undefined
      ? props.isExtraTraitMarker
        ? "hasExtraTraitMarker "
        : ""
      : "";
  return (
    <Cell>
      <div style={{ display: "flex", justifyContent: "space-between" }}>

        <div className={`headerCell ${hasExtraTraitMarker}`}>
          {n.length > 0 && <div>{n}</div>}
          {!n.length && <span>{view || keyValue}</span>}
        </div>
        {sort && (
          <button onClick={() => sortFunc(keyValue)} className='transparent-btn'>
            <i className = {activeSorting ? 'icon icon-sort sort-icon-detail-active' : 'icon icon-sort sort-icon-detail'} />
            {/* <i className='icon icon-sort-alt-up' /> */}
            {/* <i className='icon icon-sort-alt-down' /> */}
          </button>
        )}
        {filter && (
          <button onClick={() => filterFunc("col name", "filter value")}>
            <i className='icon icon-filter' />
          </button>
        )}
      </div>
    </Cell>
  );
};

HeaderCell.defaultProps = {
  view: "",
  keyValue: "",
};
HeaderCell.propTypes = {
  keyValue: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
};
export default HeaderCell;
