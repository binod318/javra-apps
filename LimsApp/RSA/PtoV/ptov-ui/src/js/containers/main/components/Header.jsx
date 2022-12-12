import React from 'react';
import { Cell } from 'fixed-data-table-2';

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

  filterVisible = () => {
    this.props.filterKeySet(this.props.children);
  };

  handleChange = (e) => {
    const { target } = e;
    const { name, value } = target;
    this.setState({
      [name]: value
    });
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
      })
      this.props.filterKeySet('');
    }
  };

  render() {
    const {
      children,
      columnKey,
      sorting,
      traitID,
      filterKey,

      data,
      selected
    } = this.props;
    const { value } = this.state;

    let match = false;
    if (traitID === null) {
      if (sorting.name === columnKey) {
        match = true;
      }
    } else {
      if (sorting.name === traitID) {
        match = true;
      }
    }

    let nofilter = true;
    let noSort = true;
    if (columnKey === 'status') {
      nofilter = false;
      noSort = false;
    }

    const ICO = sorting.direction === 'desc'
      ? <i className="action icon icon-sort-alt-down" />
      : <i className="action icon icon-sort-alt-up" />;

    if (children == 'userSelect') {
      const all = data.length === selected.length;
      return (
        <div className="cellCheckBox">
          <Cell>
            <input
              type="checkbox"
              checked={all}
              onChange={this.props.selectAll}
            />
          </Cell>
        </div>
      );
    }

    return (
      <div className="ptvheader">
        <Cell>
          {noSort && (
            <div className="btn" onClick={() => this.props.filterSort(columnKey, sorting.direction, traitID)}>
              {!match
                ? <i className="icon icon-sort" />
              : ICO}
            </div>
          )}

          <div>{children}</div>
          {nofilter && (
            <div className="btn" onClick={this.filterVisible}>
              {filterKey === children
                ? <i className="icon icon-cancel" />
                : <i className="icon icon-filter" />
              }
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
              autoFocus={true}
            />
          </div>
        )}
      </div>
    );
  }
}
export default Header;
