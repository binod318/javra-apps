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
      this.setState({ value: '' });
    }
  }

  onFilterEnter = e => {
    const { traitID, children, columnKey } = this.props;
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

  getName = (traitID, children) => {
    if (traitID === null) {
      return children;
    }
    return traitID + children;
  };

  filterVisible = () => {
    const { children, traitID } = this.props;
    this.props.filterKeySet(this.getName(traitID, children));
  };

  handleChange = e => {
    const { target } = e;
    const { name, value } = target;
    this.setState({
      [name]: value
    });
  };

  render() {
    const { children, columnKey, sorting, traitID, filterKey, colorCode } = this.props;
    const { value } = this.state;

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
    const colorCodeCheck = parseInt(colorCode, 2);
    return (
      <div className="ptvheader">
        <div className={colorCodeCheck === 1 ? 'cellOption1' : ''}>
          <Cell>
            <div
              role="button"
              tabIndex={0}
              className="btn"
              onKeyPress={() => {}}
              onClick={() =>
                this.props.filterSort(columnKey, sorting.direction, traitID)
              }
            >
              {!match ? <i className="icon icon-sort" /> : ICO}
            </div>
            <div>{children}</div>
            <div
              role="button"
              tabIndex={0}
              onKeyPress={() => {}}
              className="btn"
              onClick={this.filterVisible}
            >
              {filterKey === matchCheck ? (
                <i className="icon icon-cancel" />
              ) : (
                <i className="icon icon-filter" />
              )}
            </div>
          </Cell>
        </div>
        {filterKey === matchCheck && (
          <div
            className={
              colorCodeCheck === 1
                ? 'filterContainer cellOption1'
                : 'filterContainer'
            }
          >
            <input
              type="text"
              name="value"
              value={value}
              onChange={this.handleChange}
              onKeyPress={this.onFilterEnter}
              autoFocus // eslint-disable-line
            />
            test
          </div>
        )}
      </div>
    );
  }
}

Header.defaultProps = {
  sorting: {},
  colorCode: '',
  columnKey: '',
  children: '',
  filterKey: '',
  filterValue: '',
  traitID: null
};
Header.propTypes = {
  filterSort: PropTypes.func.isRequired,
  filterKeySet: PropTypes.func.isRequired,
  filterAdd: PropTypes.func.isRequired,
  colorCode: PropTypes.string,
  columnKey: PropTypes.string,
  data: PropTypes.array, // eslint-disable-line
  traitID: PropTypes.oneOfType([PropTypes.number, PropTypes.object]), // eslint-disable-line
  sorting: PropTypes.object, // eslint-disable-line
  children: PropTypes.string,
  filterKey: PropTypes.string,
  filterValue: PropTypes.string
};
export default Header;
