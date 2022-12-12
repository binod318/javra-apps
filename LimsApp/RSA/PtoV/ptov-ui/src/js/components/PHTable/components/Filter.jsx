import React, { Fragment } from 'react';
import PropTypes from 'prop-types';

const Filter = ({ without, withoutChange, name, filterList, filterRemove, filterClear }) => {

  const isNotPedigreeTable = name !== "pedigree";
  const noFilter = filterList.length < 1;

  if (!isNotPedigreeTable && filterList.length === 0) return null;
  const checkbox = (<div className="withoutHierarchy radioButton">
     <label htmlFor="without">
       <i className={"icon " + (without ? 'icon-ok-squared' : 'icon-check-empty')} />
       <input id="without" type="checkbox" onClick={withoutChange} />
       Filter All
     </label>
   </div>);

  const list = [];
  filterList.map((d, i) => {
    if (d.value === "") return null;
    list.push(
      <span
        role="button"
        tabIndex={0}
        key={d.name}
        onClick={() => filterRemove(d.name)}
        onKeyPress={() => {}}
      >
        <i role="button" tabIndex={0} className="icon icon-cancel" />
        {d.display}
      </span>
    );
    return null;
  });
  const filterUI = (
    <div className={"filterbar " + (isNotPedigreeTable && name != "" ? 'noPedigree' : '')}>
      { isNotPedigreeTable && name != "" ? checkbox : '' }
      { noFilter ? '' : (
        <Fragment>
          <span
            role="button"
            tabIndex={-1}
            onClick={filterClear}
            onKeyPress={() => {}}
          >
            Clear All
          </span>
          {list}
        </Fragment>
        )
      }
    </div>
   );

  return filterUI;
};

Filter.propTypes = {
  filterList: PropTypes.array, // eslint-disable-line
  filterRemove: PropTypes.func.isRequired,
  filterClear: PropTypes.func.isRequired
};
export default Filter;
