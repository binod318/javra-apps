import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';

class HeaderCell extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      children: props.columnKey,
      // data: props.data,
      // name: '',
      val: '',
      pageSize: props.pageSize
    };
  }
  componentDidMount() {
    this.props.localFilter.map(field => {
      const matchName = this.props.traitID || this.props.columnKey;

      if (field.name == matchName) { /* eslint-disable-line */
        this.setState({
          val: field.value
        });
      }
      return null;
    });
  }
  componentWillReceiveProps(nextProps) {
    nextProps.localFilter.map(field => {
      const matchName = this.props.traitID || this.props.columnKey;

      if (field.name == matchName) { /* eslint-disable-line */
        this.setState({ val: field.value });
      }
      return null;
    });
    if (nextProps.localFilter.length === 0) {
      this.setState({ val: '' });
    }
    if (nextProps.pageSize !== this.props.pageSize) {
      this.setState({ pageSize: nextProps.pageSize });
    }
  }

  _filter = () => {
    this.props.showFilter();
  };
  _filterOnChange = e => {
    const {
      target: { name, value }
    } = e;
    this.setState({
      // name: this.state.data.traitID || name,
      val: value
    });
    this.props.localFilterAdd(name, value);
  };
  _onFilterEnter = e => {
    if (e.key === 'Enter') {
      e.preventDefault();
      const { localFilter } = this.props;
      // testID, filter,
      // const { name, val } = this.state;
      // RESET MARKERS
      this.props.resetMarkers();
      // FETCH FILTER DATA
      const obj = {
        testID: this.props.testID,
        testTypeID: this.props.testTypeID,
        filter: localFilter,
        pageNumber: 1,
        pageSize: this.state.pageSize
      };
      /*
      const filt = {
        name: this.state.data.traitID || name,
        value: val,
        expression: 'contains',
        operator: 'and',
        dataType: this.state.data.dataType
      };

      const check = filter.find(d => d.name === name);
      let newFilter = '';
      if (check) {
        newFilter = filter.map(item => {
          if (item.name === name) {
            return { ...item, value: val };
          }
          return item;
        });
        this.props.addFilter(filt);
        this.props.fetch_Filter_data({
          ...obj, ...{ filter: newFilter }
        });
        // this.props.fetchDate(1, pagesize, newFilter);
      } else {
        this.props.addFilter(filt);
        this.props.fetch_Filter_data({
          ...obj, ...{
            filter: filter.concat(filt)
          }
        });
      }
      */
      this.props.setIndexArray(null);
      this.props.fetch_Filter_data(obj);
    }
  };

  render() {
    const { children } = this.state;
    return (
      <div>
        <div className="headerCell">
          <span name={children}>{this.props.label}</span>
          <span className="filterBtn">
            <i className="icon-filter" onClick={this._filter} /> {/*eslint-disable-line*/}
          </span>
        </div>
        <div className="filterBox">
          <input
            type="text"
            name={this.props.columnKey}
            ref={this.props.columnKey}
            value={this.state.val}
            onChange={this._filterOnChange}
            onKeyPress={this._onFilterEnter}
          />
        </div>
      </div>
    );
  }
}
HeaderCell.defaultProps = {
  traitID: null
};
HeaderCell.propTypes = {
  columnKey: PropTypes.oneOfType([PropTypes.string, PropTypes.number])
    .isRequired,
  label: PropTypes.string.isRequired,
  testID: PropTypes.number.isRequired,
  testTypeID: PropTypes.number.isRequired,
  traitID: PropTypes.number,
  pageSize: PropTypes.number.isRequired,
  showFilter: PropTypes.func.isRequired,
  fetch_Filter_data: PropTypes.func.isRequired,
  resetMarkers: PropTypes.func.isRequired,
  localFilterAdd: PropTypes.func.isRequired,
  setIndexArray: PropTypes.func.isRequired,
  // addFilter: PropTypes.func.isRequired,
  // data: PropTypes.object.isRequired, // eslint-disable-line react/forbid-prop-types
  // filter: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  localFilter: PropTypes.array.isRequired // eslint-disable-line react/forbid-prop-types
};
const mapStateToProps = state => ({
  testID: state.assignMarker.file.selected.testID,
  testTypeID: state.assignMarker.testType.selected,
  filter: state.assignMarker.filter
});
const mapDispatchToProps = dispatch => ({
  addFilter: obj => {
    dispatch({
      type: 'FILTER_ADD',
      name: obj.name,
      value: obj.value,
      expression: 'contains',
      operator: 'and',
      dataType: obj.dataType,
      traitID: obj.traitID
    });
  },
  resetMarkers: () => dispatch({ type: 'MARKER_TO_FALSE' }),
  fetch_Filter_data: obj => {
    dispatch({
      type: 'FETCH_FILTERED_DATA',
      testID: obj.testID,
      testTypeID: obj.testTypeID,
      filter: obj.filter,
      pageNumber: obj.pageNumber,
      pageSize: obj.pageSize
    });
  }
});
export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HeaderCell);
