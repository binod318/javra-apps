import React from 'react';
import { Cell } from 'fixed-data-table-2';
import PropTypes from 'prop-types';

class Header extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      value: props.filterValue
    };
  }
  componentWillReceiveProps(nextProps) {
    if (nextProps.filterValue === '') {
      this.setState({
        value: ''
      });
    }
  }

  onFilterEnter = e => {
    if (e.key === 'Enter') {
      this.props.filterAdd({
        display: this.props.children,
        name: this.props.columnKey,
        value: this.state.value,
        expression: 'contains',
        operator: 'and'
      });
      this.props.filterKeySet('');
    }
  };
  filterVisible = () => {
    this.props.filterKeySet(this.props.children);
  };

  handleChange = e => {
    const { target } = e;
    const { name, value } = target;
    this.setState({
      [name]: value
    });
  };

  render() {
    const {
      children,
      sortable,
      filterble,
      filterKey,
      columnKey,
      check,
      sorting
    } = this.props;
    const { value } = this.state;

    const ICO =
      sorting.direction === 'desc' ? (
        <i className="action icon icon-sort-alt-down" />
      ) : (
        <i className="action icon icon-sort-alt-up" />
      );

    return (
      <div className="ptvheader">
        <Cell>
          {sortable && (
            <div
              role="button"
              tabIndex={0}
              onKeyPress={() => {}}
              className="btn"
              onClick={() =>
                this.props.filterSort(columnKey, sorting.direction)
              }
            >
              {sorting.name !== columnKey ? (
                <i className="icon icon-sort" />
              ) : (
                ICO
              )}
            </div>
          )}

          {!check && <div>{children}</div>}

          {filterble && (
            <div
              role="button"
              tabIndex={0}
              onKeyPress={() => {}}
              className="btn"
              onClick={this.filterVisible}
            >
              {filterKey === children ? (
                <i className="icon icon-cancel" />
              ) : (
                <i className="icon icon-filter" />
              )}
            </div>
          )}
        </Cell>
        {filterKey === children && (
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
  sortable: false,
  filterble: false,
  filterValue: '',
  filterKey: '',
  columnKey: '',
  check: false,
  children: '',
  sorting: {}
};
Header.propTypes = {
  sortable: PropTypes.bool,
  filterble: PropTypes.bool,
  check: PropTypes.bool,
  filterValue: PropTypes.string,
  columnKey: PropTypes.string,
  filterKey: PropTypes.string,
  children: PropTypes.string, // eslint-disable-line
  sorting: PropTypes.object, // eslint-disable-line
  filterKeySet: PropTypes.func.isRequired,
  filterAdd: PropTypes.func.isRequired,
  filterSort: PropTypes.func.isRequired
};
export default Header;
