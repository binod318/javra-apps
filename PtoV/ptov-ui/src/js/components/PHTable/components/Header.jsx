import React from 'react';
import { Cell } from 'fixed-data-table-2';
import PropTypes from 'prop-types';

class Header extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      name: props.name,
      value: props.filterValue || '',
      selected: props.deleteList ? true : false
    };
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.filterValue === '') {
      this.setState({
        value: ''
      });
    }
    if (nextProps.deleteList && nextProps.deleteList.length === 0) {
      this.setState({ selected: false });
    }
  }

  onFilterEnter = e => {
    let { traitID } = this.props;
    const { name, children, columnKey } = this.props;
    if (name === "pedigree") {
      /**
       * normally if there is traidID we will fetch using traidID
       * But in Phenome response data, they got traidID and data not link to it
       * else link to pedigreeColID so have to use this patch
       */
      traitID = null;
    }
    if (e.key === 'Enter') {
      this.props.filterAdd({
        display: children,
        name: traitID !== null ? traitID : columnKey,
        value: this.state.value,
        expression: 'contains',
        operator: 'and'
      });
      this.props.filterKeySet('');
    }
  };

  select = col => {
    const { traitID } = this.props;
    const { selected } = this.state;
    this.setState({
      selected: !selected
    });
    this.props.deleteColumn(col, traitID, !selected);
  }

  getName = (traitID, children) => {
    if (traitID === null) {
      return children;
    }
    return traitID + children;
  };

  handleChange = e => {
    const { target } = e;
    const { name, value } = target;
    this.setState({
      [name]: value
    });
  };

  filterVisible = () => {
    const { children, traitID } = this.props;
    this.props.filterKeySet(this.getName(traitID, children));
  };

  deleteColumn = col => {
    const { traitID } = this.props;
    this.props.deleteColumn(col, traitID);
  };

  render() {
    const {
      children,
      columnKey,
      sorting,
      traitID,
      filterKey,
      colorCode,
      filterList
    } = this.props;
    let { name, value } = this.state;
    
    const isThispedigree = name !== 'pedigree';

    let match = false;
    if (traitID === null) {
      if (sorting.name === columnKey) {
        match = true;
      }
    } else {
      match = sorting.name === traitID;
    }

    const ICO =
      sorting.direction === 'desc' ? (
        <i className="action icon icon-sort-alt-down" />
      ) : (
        <i className="action icon icon-sort-alt-up" />
      );

    const matchCheck = this.getName(traitID, children);

    let nofilter = true;
    let noSort = true;
    if (columnKey === 'status') {
      noSort = false;
    }
    const showTrashBtn = colorCode === 1;

    return (
      <div className="ptvheader">
        <div className={colorCode === 1 ? 'cellOption1' : ''}>
          <Cell>
            {!showTrashBtn && noSort && isThispedigree && (
              <div
                role="button"
                tabIndex={0}
                className="btn"
                onClick={() =>
                  this.props.filterSort(columnKey, sorting.direction, traitID)
                }
                onKeyPress={() => {}}
              >
                {!match ? <i className="icon icon-sort" /> : ICO}
              </div>
            )}

            <div>{children}</div>
            {!showTrashBtn && nofilter && (
              <div
                role="button"
                tabIndex={0}
                className="btn"
                onClick={this.filterVisible}
                onKeyPress={() => {}}
              >
                {filterKey === matchCheck ? (
                  <i className="icon icon-cancel" />
                ) : (
                  <i className="icon icon-filter" />
                )}
              </div>
            )}

            {showTrashBtn && (
              <div className="trashHead radioButton trash">
                <label htmlFor={columnKey}>
                  <i className={"icon " + (this.state.selected ? 'icon-ok-squared' : 'icon-check-empty')} />
                  <input id={columnKey} value={this.state.selected} type="checkbox" onClick={() => this.select(children)} />
                </label>
              </div>
            )}
            {showTrashBtn && false && (
              <div
                role="button"
                tabIndex={0}
                className="btn trash"
                onClick={() => this.deleteColumn(children)}
                onKeyPress={() => {}}
              >
                {/*<i className="icon icon-trash" />*/}
                <i
                  className="icon icon-check-empty"
                  style={{
                    fontSize: '14px',
                    position: 'relative',
                    top: '2px'
                  }}
                />
              </div>
            )}
          </Cell>
        </div>
        {filterKey === matchCheck && (
          <div className="filterContainer">
            <input
              type="text"
              name="value"
              value={value}
              onChange={this.handleChange}
              onKeyPress={this.onFilterEnter}
              autoFocus={true} // eslint-disable-line
            />
          </div>
        )}
      </div>
    );
  }
}

Header.defaultProps = {
  name: '',
  filterValue: '12',
  filterKey: '',
  columnKey: '',
  colorCode: 0,
  traitID: null,
  filterList: []
};
Header.propTypes = {
  name: PropTypes.string,
  filterValue: PropTypes.string,
  columnKey: PropTypes.string,
  filterKey: PropTypes.string,
  colorCode: PropTypes.number,
  children: PropTypes.string.isRequired, // eslint-disable-line
  sorting: PropTypes.object, // eslint-disable-line
  filterList: PropTypes.array, // eslint-disable-line
  traitID: PropTypes.number,
  filterKeySet: PropTypes.func.isRequired,
  filterAdd: PropTypes.func.isRequired,
  filterSort: PropTypes.func.isRequired,
  deleteColumn: PropTypes.func.isRequired,
};
export default Header;
