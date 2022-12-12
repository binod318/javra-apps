import React from 'react';

const Filter = ({ filterList, filterRemove, filterClear }) => {
  if (filterList.length < 1) {
    return null;
  }
  let list = [];
  {filterList.map((d, i) => {
    list.push(
      <span
        key={i}
        onClick={() => {filterRemove(d.name)}}
      >
        <i
          role="button"
          tabIndex={0}
          className="icon icon-cancel"
        />
        {d.display}
      </span>
    );
  })}
  return (
    <div className="filterbar">
      <span onClick={filterClear}>Clear All</span>
      {list}
    </div>
  );
}
export default Filter;
