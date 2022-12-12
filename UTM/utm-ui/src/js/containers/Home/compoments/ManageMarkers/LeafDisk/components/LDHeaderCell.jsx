import React, { Component } from "react";
import { connect } from "react-redux";
import PropTypes from "prop-types";
import autoBind from "auto-bind";

class HeaderComponent extends Component {
  constructor(props) {
    super(props);
    this.state = {
      data: props.data, // eslint-disable-line
      val: "",
      determinationMarkerChecked: false
    };
    autoBind(this);
  }
  componentDidMount() {
    const { filters } = this.props;
    const { columnKey } = this.props;
    const val = filters[columnKey] ? filters[columnKey].value : "";
    this.setState({ val }); // eslint-disable-line
  }
  componentWillReceiveProps(nextProps) {
    const { filters } = nextProps;
    const { columnKey } = this.props;
    const val = filters[columnKey] ? filters[columnKey].value : "";
    this.setState({ val });
  }

  componentDidUpdate(prevProps) {
    if (
      this.props.determinationChangedSaved &&
      prevProps.determinationChangedSaved !==
        this.props.determinationChangedSaved
    ) {
      // eslint-disable-next-line react/no-did-update-set-state
      this.setState({ determinationMarkerChecked: false });
      this.props.resetDeterminationChangedSavedFlag();
    }
  }

  handleFilterChange(e) {
    // const { data } = this.props;

    this.setState({
      val: e.target.value
    });
  }

  handleKeyPress(e) {
    if (e.key !== "Enter") return;
    e.preventDefault();

    const { data } = this.props;
    const obj = {
      name: data.columnID,
      value: this.state.val,
      expression: "contains",
      operator: "and",
      dataType: this.props.data.dataType
    };
    // save updated filter for later use
    this.props.addLeafDiskFilter({ key: data.columnID, value: obj });

    // prep updated filter for now
    const filters = {
      ...this.props.filters,
      [data.columnID]: obj
    };

    const payload = {
      testID: this.props.testID,
      filter: Object.values(filters),
      pageNumber: 1,
      pageSize: 200
    };
    this.props.fetchData(payload);
  }
  toggleAllLDMarkers(e) {
    const determinationMarkerChecked = e.target.checked;
    this.setState({
      determinationMarkerChecked
    });
    const { columnID } = this.props.data;
    this.props.toggleAllLDMarkers(columnID, determinationMarkerChecked);
  }

  filterInputElement = () => {
    const placeholderCondition =
      this.props.columnKey.toString().substring(0, 2) === "D_";
    return (
      <div className="filterBox">
        <input
          type="text"
          tabIndex="-1"
          name={this.props.columnKey}
          ref={this.props.columnKey}
          value={this.state.val}
          onChange={this.handleFilterChange}
          onKeyPress={this.handleKeyPress}
          autoComplete="off"
          placeholder={placeholderCondition ? "1 / 0" : ""}
        />
      </div>
    );
  };

  render() {
    const { label, statusCode, data } = this.props;
    const statusDisabled = statusCode >= 400;

    const checkHeaderCondition = data.dataType === "boolean";
    return (
      <div title={label}>
        <div className="headerCell">
          {checkHeaderCondition && (
            <div className="check-all-marker tableCheck">
              <input
                id={data.columnID}
                type="checkbox"
                disabled={statusDisabled}
                checked={this.state.determinationMarkerChecked}
                onChange={this.toggleAllLDMarkers}
              />
              <label htmlFor={data.columnID} /> {/* eslint-disable-line */}
            </div>
          )}
          <span>{label}</span>
          {data.allowFilter && label !== "Print" && (
            <span
              className="filterBtn"
              onClick={this.props.showFilter}
              role="button"
              onKeyDown={() => {}}
              tabIndex="0"
            >
              <i className="icon-filter" />
            </span>
          )}
        </div>

        {data.allowFilter && this.filterInputElement()}
      </div>
    );
  }
}

const mapStateToProps = state => ({
  testID: state.assignMarker.file.selected.testID,
  filters: state.assignMarker.leafDiskFilters,
  statusCode: state.rootTestID.statusCode,
  determinationChangedSaved:
    state.assignMarker.determinations.determinationChangedSaved
});

const mapDispatchToProps = dispatch => ({
  addLeafDiskFilter: payload =>
    dispatch({ type: "ADD_LEAF_DISK_FILTER", payload }),
  toggleAllLDMarkers: (marker, checkedStatus) =>
    dispatch({
      type: "TOGGLE_ALL_LD_MARKERS",
      marker,
      checkedStatus
    }),
  resetDeterminationChangedSavedFlag: () =>
    dispatch({
      type: "RESET_DETERMINATION_CHANGED_SAVED_FLAG"
    })
});

HeaderComponent.defaultProps = {
  columnKey: "",
  label: ""
};

HeaderComponent.propTypes = {
  filters: PropTypes.any, // eslint-disable-line
  showFilter: PropTypes.func.isRequired,
  testID: PropTypes.number.isRequired,
  data: PropTypes.object.isRequired, // eslint-disable-line react/forbid-prop-types
  columnKey: PropTypes.string,
  label: PropTypes.string,
  statusCode: PropTypes.number.isRequired,
  addLeafDiskFilter: PropTypes.func.isRequired,
  toggleAllLDMarkers: PropTypes.func.isRequired,
  fetchData: PropTypes.func.isRequired,
  resetDeterminationChangedSavedFlag: PropTypes.func.isRequired,
  determinationChangedSaved: PropTypes.bool.isRequired
};

const MaterialHeaderCell = connect(
  mapStateToProps,
  mapDispatchToProps
)(HeaderComponent);
export default MaterialHeaderCell;
