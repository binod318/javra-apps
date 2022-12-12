import React from 'react';
import PropTypes from 'prop-types';

class HeaderCell extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      value: props.value,
      columnKey: props.columnKey,
      val: ''
    };
  }
  componentDidMount() {
    this.props.localFilter.map(field => {
      const matchName = this.props.columnKey;
      if (field.name == matchName) {  // eslint-disable-line
        this.setState({
          val: field.value || ''
        });
      }
      return null;
    });
  }
  componentWillReceiveProps(nextProps) {
    nextProps.localFilter.map(field => {
      const matchName = this.props.columnKey;
      if (field.name == matchName) this.setState({ val: field.value }); // eslint-disable-line
      return null;
    });
    if (nextProps.localFilter.length === 0) this.setState({ val: '' });
  }

  onFilterEnter = e => {
    if (e.key === 'Enter') this.props.filterFetch();
  };

  filterOnChange = e => {
    const {
      target: { name, value }
    } = e;
    this.setState({ val: value });
    this.props.localFilterAdd(name, value);
  };

  render() {
    const { value, columnKey, val } = this.state;
    return (
      <div>
        <div className="headerCell">
          <span>{value.name}</span>
          {value.filter && (
            <span className="filterBtn">
              <i
                role="presentation"
                className="icon-filter"
                onClick={() => this.props.handle(columnKey)}
              />
            </span>
          )}
        </div>
        {value.filter && (
          <div className="filterBox">
            <input
              name={this.props.columnKey}
              type="text"
              value={val}
              onChange={this.filterOnChange}
              onKeyPress={this.onFilterEnter}
            />
          </div>
        )}
      </div>
    );
  }
}

HeaderCell.defaultProps = {
  columnKey: '',
  localFilter: [],
  localFilterAdd: () => {}
};
HeaderCell.propTypes = {
  value: PropTypes.object.isRequired, // eslint-disable-line react/forbid-prop-types
  localFilter: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  localFilterAdd: PropTypes.func,
  filterFetch: PropTypes.func.isRequired,
  handle: PropTypes.func.isRequired,
  columnKey: PropTypes.string
};

export default HeaderCell;
