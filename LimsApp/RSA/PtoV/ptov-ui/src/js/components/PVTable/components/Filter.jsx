import React from 'react';
import PropTypes from 'prop-types';

const Filter = ({ filterList, filterRemove, filterClear }) => {
  if (filterList.length < 1) {
    return null;
  }
  const list = [];
  filterList.map((d, i) => {
    list.push(
      <span
        role="button"
        tabIndex={0}
        onKeyPress={() => {}}
        key={d.name}
        onClick={() => filterRemove(d.name)}
      >
        <i
          role="button"
          tabIndex={0}
          onKeyPress={() => {}}
          className="icon icon-cancel"
        />
        {d.display}
      </span>
    );
    return null;
  });
  return (
    <div className="filterbar">
      <span
        role="button"
        tabIndex={0}
        onKeyPress={() => {}}
        onClick={filterClear}
      >
        Clear All
      </span>
      {list}
    </div>
  );
};

Filter.propTypes = {
  filterList: PropTypes.array, // eslint-disable-line
  filterRemove: PropTypes.func.isRequired,
  filterClear: PropTypes.func.isRequired
};
export default Filter;
