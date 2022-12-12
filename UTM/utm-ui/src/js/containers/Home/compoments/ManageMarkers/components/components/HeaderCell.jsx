import React, { Component } from "react";
import { connect } from "react-redux";
// import { Cell } from 'fixed-data-table-2';
import PropTypes from "prop-types";
import autoBind from "auto-bind";
import {
  addMaterialFilter,
  // fetchFilteredMaterial,
  toggleAllMarkers,
  toggleAll3GBMarkers
} from "../../../../../Home/actions";

class HeaderComponent extends Component {
  constructor(props) {
    super(props);
    this.state = {
      children: props.columnKey,
      columnKey: props.sort, // eslint-disable-line
      data: props.data, // eslint-disable-line
      val: "",
      traitID: props.traitID, // eslint-disable-line
      pageNumber: props.pageNumber, // eslint-disable-line
      pageSize: props.pageSize,
      determinationMarkerChecked: false,
      name: props.name
    };
    autoBind(this);
  }
  componentDidMount() {
    const { filters } = this.props;
    const key = this.props.traitID || this.props.columnKey;
    const val = filters[key] ? filters[key].value : "";
    this.setState({ val }); // eslint-disable-line
  }
  componentWillReceiveProps(nextProps) {
    const { filters } = nextProps;
    if (this.props.testTypeID !== 8) {
      const key = this.props.traitID || this.props.columnKey;
      const val = filters[key] ? filters[key].value : "";
      this.setState({ val });
    }

    /**
     * RDT clear value in input element
     * after filter is cleared
     */
    if (nextProps.RDTfilters.length === 0 && this.props.testTypeID === 8) {
      this.setState({ val: "" });
    }

    if (nextProps.pageNumber !== this.props.pageNumber) {
      this.setState({
        pageNumber: nextProps.pageNumber // eslint-disable-line
      });
    }
    if (nextProps.pageSize !== this.props.pageSize) {
      this.setState({
        pageSize: nextProps.pageSize
      });
    }
  }

  _filter() {
    this.props.showFilter();
  }
  _filterOnChangeRDT(e) {
    switch (this.props.testTypeID) {
      case 10: {
        // Seed Health
        const obj = {
          name: this.props.data.label || this.props.data.columnLabel,
          value: e.target.value,
          expression: "contains",
          operator: "and",
          dataType: this.props.data.dataType
        };

        this.props.addSeedHealthFilter(obj);
        this.props.addFilter(obj);
        this.setState({
          val: e.target.value
        });
        break;
      }
      case 9: {
        // LeafDisk
        const obj = {
          name: this.props.data.label || this.props.data.columnLabel,
          value: e.target.value,
          expression: "contains",
          operator: "and",
          dataType: this.props.data.dataType
        };

        this.props.addLeafDiskFilter(obj);
        this.props.addFilter(obj);
        this.setState({
          val: e.target.value
        });
        break;
      }
      case 8: {
        // RDT
        const filterName =
          this.props.data.traitID ||
          this.props.data.columnLabel ||
          this.props.data.label;

        const obj = {
          name: filterName,
          value: e.target.value,
          expression: "contains",
          operator: "and",
          dataType: this.props.data.dataType
        };

        this.setState({
          val: e.target.value
        });
        this.props.addRDTFilter(obj);
        this.props.addFilter(obj);
        if (this.props.columnKey === "MaterialStatus") this.RDTFilterCall();
        break;
      }
      default:
        break;
    }
  }

  _filterOnChangeMaterialRDT = e => {
    const { name, value } = e.target;
    let found = false;

    const filterName = this.props.data.traitID || this.props.data.columnLabel;
    const obj = {
      name: filterName,
      value: e.target.value,
      expression: "contains",
      operator: "and",
      dataType: this.props.data.dataType
    };
    const filter = Object.keys(this.props.RDTfilters).map(
      key => this.props.RDTfilters[key]
    );
    const nfilter = filter.map(k => {
      if (k.name === name) {
        found = true;
        return { ...k, value };
      }
      return k;
    });
    if (!found) {
      nfilter.push(obj);
    }

    if (nfilter.length === 1 && nfilter[0].value === "") {
      this.props.rdtFilterClear();
      this.setState({ val: e.target.value });
      this.props.fetchFilteredMaterialRDT({
        testID: this.props.testID,
        filter: [],
        pageNumber: 1,
        pageSize: this.state.pageSize
      });
      return null;
    }

    const obj2 = {
      testID: this.props.testID,
      filter: nfilter.length ? nfilter : [obj],
      pageNumber: 1,
      pageSize: this.state.pageSize
    };
    this.setState({ val: e.target.value });
    this.props.addRDTFilter(obj);
    this.props.fetchFilteredMaterialRDT(obj2);
    return null;
  };

  _onFilterEnterRDT(e) {
    if (e.key !== "Enter") return;
    e.preventDefault();
    switch (this.props.testTypeID) {
      case 8: {
        // RDT
        this.RDTFilterCall();
        break;
      }
      case 9: {
        // Leaf disk
        this.filterLeafDisk();
        break;
      }
      default: {
        break;
      }
    }
  }
  RDTFilterCall = () => {
    const filter = Object.keys(this.props.RDTfilters).map(
      key => this.props.RDTfilters[key]
    );
    const obj = {
      testID: this.props.testID,
      filter,
      pageNumber: 1,
      pageSize: this.state.pageSize
    };
    this.props.fetchFilteredMaterialRDT(obj);
  };

  filterLeafDisk = () => {
    const filter = Object.keys(this.props.leafDiskFilters).map(
      key => this.props.leafDiskFilters[key]
    );
    const obj = {
      testID: this.props.testID,
      filter,
      pageNumber: 1,
      pageSize: this.state.pageSize
    };
    this.props.fetchFilteredLeafDisk(obj);
  };

  _filterOnChange(e) {
    const filterName = this.props.data.traitID || this.props.data.columnLabel;

    const eleType = e.target.type === "checkbox";
    const checkboxValue = e.target.checked ? 1 : 0;
    const obj = {
      name: filterName,
      value: eleType ? checkboxValue : e.target.value,
      expression: "contains",
      operator: "and",
      dataType: this.props.data.dataType
    };
    this.setState({
      val: e.target.value
    });
    this.props.addFilter(obj);
  }

  _onFilterEnter(e) {
    const that = this;
    if (e.target.type === "checkbox") {
      setTimeout(() => {
        const filter = Object.keys(that.props.filters).map(
          key => that.props.filters[key]
        );
        const obj = {
          testID: that.props.testID,
          filter,
          pageNumber: 1,
          pageSize: that.state.pageSize
        };
        that.props.fetchFilteredMaterial(obj);
      }, 500);
    }
    if (e.key === "Enter") {
      e.preventDefault();
      const filter = Object.keys(this.props.filters).map(
        key => this.props.filters[key]
      );
      const obj = {
        testID: this.props.testID,
        filter,
        pageNumber: 1,
        pageSize: this.state.pageSize
      };
      this.props.fetchFilteredMaterial(obj);
    }
  }

  toggleAllMarkers(e) {
    const determinationMarkerChecked = e.target.checked;
    this.setState({
      determinationMarkerChecked
    });

    const lowerTraidId = this.state.traitID.toLowerCase();
    this.props.toggleAllMarkers(lowerTraidId, determinationMarkerChecked);
  }
  toggleAll3GBMark(e) {
    const determinationMarkerChecked = e.target.checked;
    this.setState({
      determinationMarkerChecked
    });
    this.props.toggleAll3GB(determinationMarkerChecked);
  }

  filterEnputElement = () => {
    if (this.props.columnKey === "MaterialStatus") {
      return (
        <div className="filterBox">
          <select
            tabIndex="-1"
            name={this.props.columnKey}
            ref={this.props.columnKey}
            value={this.state.val}
            onChange={this._filterOnChangeMaterialRDT}
          >
            <option value="" />
            {this.props.msterialStateRDT.map(p => (
              <option key={p.code} value={p.name}>
                {p.name}
              </option>
            ))}
          </select>
        </div>
      );
    }
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
          onChange={this._filterOnChangeRDT}
          onKeyPress={this._onFilterEnterRDT}
          autoComplete="off"
          placeholder={placeholderCondition ? "1 / 0" : ""}
        />
      </div>
    );
  };

  render() {
    const { traitID, label, testTypeID, statusCode, testID } = this.props;
    const statusDisabled = statusCode >= 400;
    const { children } = this.state;
    // //////////////////////////
    // / ## HOT 3GB CHANGE
    // / ///////////////////////////
    // if (children === 'To3GB') {
    // d_ addect condtion. impact don't know 16/07/2019
    // D_Selected, d_Selected
    if (children.toLowerCase() === "d_selected") {
      return (
        <div>
          <div className="headerCell">
            <div className="check-all-marker tableCheck">
              <input
                id="alltoggle3gb"
                type="checkbox"
                disabled={statusDisabled}
                checked={this.state.determinationMarkerChecked}
                onChange={this.toggleAll3GBMark}
              />
              <label htmlFor={`alltoggle3gb`} /> {/* eslint-disable-line */}
            </div>
            <span name={children}>{label}</span>
            {this.state.name === "3gb" && (
              <span
                className="filterBtn"
                onClick={this._filter}
                role="button"
                onKeyDown={() => {}}
                tabIndex="0"
              >
                <i className="icon-filter" />
              </span>
            )}
          </div>
          <div className="filterBox">
            <div className="selectedFilter3gb">
              <div>
                <input
                  type="checkbox"
                  name="test"
                  id="Selected3gb"
                  onClick={e => {
                    this._onFilterEnter(e);
                  }}
                  onChange={this._filterOnChange}
                />
              </div>
              {this.state.val !== "" && (
                <div>
                  <button
                    onClick={() => {
                      this.props.fetchFilteredMaterial({
                        testID,
                        filter: [],
                        pageNumber: 1,
                        pageSize: this.state.pageSize
                      });
                      this.props.filterclear3gb();
                      document.getElementById("Selected3gb").checked = false;
                      this.setState({
                        val: ""
                      });
                    }}
                    title="Clear filter"
                  >
                    <i className="icon icon-cancel" />
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      );
    }

    const checkHeaderCondition =
      traitID &&
      statusDisabled !== true &&
      traitID.toString().substring(0, 2) === "D_";
    const RDTtype = testTypeID === 8;
    const leafDiskType = testTypeID === 9;
    return (
      <div title={label}>
        <div className="headerCell">
          {checkHeaderCondition && (
            <div className="check-all-marker tableCheck">
              <input
                id={traitID}
                type="checkbox"
                disabled={statusDisabled}
                checked={this.state.determinationMarkerChecked}
                onChange={this.toggleAllMarkers}
              />
              <label htmlFor={traitID} /> {/* eslint-disable-line */}
            </div>
          )}
          <span name={children}>{label}</span>
          {(RDTtype || leafDiskType) && label !== "Print" && (
            <span
              className="filterBtn"
              onClick={this._filter}
              role="button"
              onKeyDown={() => {}}
              tabIndex="0"
            >
              <i className="icon-filter" />
            </span>
          )}
        </div>

        {(RDTtype || leafDiskType) && this.filterEnputElement()}
      </div>
    );
  }
}

const mapStateToProps = state => ({
  testID: state.assignMarker.file.selected.testID,
  testTypeID: state.assignMarker.testType.selected,
  filters: state.assignMarker.materials.filters,
  statusCode: state.rootTestID.statusCode,
  msterialStateRDT: state.assignMarker.materialStateRDT,
  RDTfilters: state.assignMarker.RDTFilter,
  leafDiskFilters: state.assignMarker.leafDiskFilters
});

const mapDispatchToProps = dispatch => ({
  addFilter: obj => dispatch(addMaterialFilter(obj)),
  addRDTFilter: obj => dispatch({ type: "RDT_FILTER_ADD", ...obj }),
  addLeafDiskFilter: obj => dispatch({ type: "ADD_LEAF_DISK_FILTER", ...obj }),
  addSeedHealthFilter: obj => dispatch({ type: "ADD_SEED_HEALTH_FILTER", ...obj }),
  fetchFilteredLeafDisk: obj => {
    dispatch({ type: "FETCH_LEAF_DISK_SAMPLE_DATA", options: obj });
  },
  fetchFilteredSeedHealth: obj => {
    dispatch({ type: "FETCH_SEED_HEALTH_SAMPLE_DATA", options: obj });
  },
  fetchFilteredMaterial: obj => {
    dispatch({ type: "FETCH_THREEGB", ...obj });
    // dispatch(fetchFilteredMaterial(obj));
  },
  fetchFilteredMaterialRDT: obj => {
    dispatch({ type: "FETCH_RDT_MATERIAL_WITH_TESTS", ...obj });
  },
  toggleAllMarkers: (marker, checkedStatus) =>
    dispatch(toggleAllMarkers(marker, checkedStatus)),
  toggleAll3GB: checkedStatus => dispatch(toggleAll3GBMarkers(checkedStatus)),
  filterclear3gb: () => dispatch({ type: "CLEAR_MARKER_FILTER" }),
  rdtFilterClear: () => dispatch({ type: "RDT_FILTER_CLEAR" })
});

HeaderComponent.defaultProps = {
  columnKey: "",
  label: "",
  testTypeID: 0,
  name: "",
  msterialStateRDT: []
};

HeaderComponent.propTypes = {
  msterialStateRDT: PropTypes.array, // eslint-disable-line
  filterclear3gb: PropTypes.func.isRequired,
  rdtFilterClear: PropTypes.func.isRequired,
  fetchFilteredMaterialRDT: PropTypes.func.isRequired,
  addRDTFilter: PropTypes.func.isRequired,
  name: PropTypes.string,
  RDTfilters: PropTypes.any, // eslint-disable-line
  filters: PropTypes.any, // eslint-disable-line
  traitID: PropTypes.any, // eslint-disable-line
  testTypeID: PropTypes.number,
  toggleAll3GB: PropTypes.func.isRequired,
  showFilter: PropTypes.func.isRequired,
  fetchFilteredMaterial: PropTypes.func.isRequired,
  addFilter: PropTypes.func.isRequired,
  testID: PropTypes.number.isRequired,
  data: PropTypes.object.isRequired, // eslint-disable-line react/forbid-prop-types
  columnKey: PropTypes.string,
  pageNumber: PropTypes.number.isRequired,
  pageSize: PropTypes.number.isRequired,
  // filters: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  toggleAllMarkers: PropTypes.func.isRequired,
  label: PropTypes.string,
  statusCode: PropTypes.number.isRequired,
  leafDiskFilters: PropTypes.any, // eslint-disable-line
  addLeafDiskFilter: PropTypes.func.isRequired,
  seedHealthFilters: PropTypes.any,
  addSeedHealthFilter: PropTypes.func.isRequired
};

const MaterialHeaderCell = connect(
  mapStateToProps,
  mapDispatchToProps
)(HeaderComponent);
export default MaterialHeaderCell;
