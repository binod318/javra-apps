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
      val: ''
      // pageSize: props.pageSize
    };
  }
  componentDidMount() {
    this.props.localFilter.map(field => {
      const matchName = this.props.traitID || this.props.columnKey;
      if (field.name === matchName) {
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
      if (field.name === matchName) {
        this.setState({ val: field.value });
      }
      return null;
    });
    if (nextProps.localFilter.length === 0) {
      this.setState({ val: '' });
    }
    // if (nextProps.pageSize !== this.props.pageSize) {
    //   this.setState({ pageSize: nextProps.pageSize });
    // }
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
      this.props.fetch_FilterPlate_data();
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
  traitID: null,
  localFilter: []
};
HeaderCell.propTypes = {
  columnKey: PropTypes.string.isRequired,
  label: PropTypes.string.isRequired,
  // testID: PropTypes.number.isRequired,
  traitID: PropTypes.string,
  // pageSize: PropTypes.number.isRequired,
  showFilter: PropTypes.func.isRequired,
  localFilterAdd: PropTypes.func.isRequired,
  fetch_FilterPlate_data: PropTypes.func.isRequired,
  // addFilter: PropTypes.func.isRequired,
  // data: PropTypes.object.isRequired, // eslint-disable-line react/forbid-prop-types
  // filter: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  localFilter: PropTypes.array // eslint-disable-line react/forbid-prop-types
};
const mapStateToProps = (state, ownProps) => ({
  filter: state.plateFilling.filter,
  fetchData: ownProps.fetchData
});
export default connect(
  mapStateToProps,
  null
)(HeaderCell);
