import React, { Fragment } from "react";
import { connect } from "react-redux";
import PropTypes from "prop-types";
import Markers from "../Marker/Markers";
import TableData from "./components/TableData";
import Page from "../../../../components/Page/Page";
import AddMaterialsToSampleModal from "../ManageMarkers/components/components/AddMaterialsToSampleModal";

class MarkerAssign extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      selectArray: [],
      addSampleModalVisible: false
    };
  }
  setIndexArray = index => {
    if (index === null) this.setState({ selectArray: [] });
    else this.setState({ selectArray: index });
  };

  addToS2S = () => {
    const { selectArray } = this.state;
    const { dataList } = this.props;
    const materialIDFromSelectedArray = selectArray.map(selectedObj => {
      const { materialKey } = dataList[selectedObj];
      return { materialKey, selected: true };
    });

    this.props.addToS2S(materialIDFromSelectedArray);
  };

  addToThreeGBList = () => {
    const { selectArray } = this.state;
    const { dataList } = this.props;
    const materialIDFromSelectedArray = selectArray.map(selectedObj => {
      const { materialKey } = dataList[selectedObj];
      return { materialKey, selected: true };
    });
    this.props.addToThreeGBList(materialIDFromSelectedArray);
  };

  selectRow = (rowIndex, shift, match, ctrl) => {
    if (rowIndex === null) {
      return null;
    }
    const { selectArray } = this.state;
    const { dataList } = this.props;

    if (ctrl) {
      if (!selectArray.includes(rowIndex)) {
        this.setIndexArray([...selectArray, rowIndex]);
      } else {
        const ind = selectArray.indexOf(rowIndex);
        const newSelect = [
          ...selectArray.slice(0, ind),
          ...selectArray.slice(ind + 1)
        ];
        this.setIndexArray(newSelect);
      }
    } else if (shift) {
      const newShiftArray = this.state.selectArray;
      newShiftArray.push(rowIndex);
      newShiftArray.sort((a, b) => a - b);
      const preArray = [];
      for (
        let i = newShiftArray[0];
        i <= newShiftArray[newShiftArray.length - 1];
        i += 1
      ) {
        if (!dataList[i].fixed) {
          preArray.push(i);
        }
      }
      this.setIndexArray(preArray);
    } else {
      const checkSelect = selectArray.includes(rowIndex);
      if (checkSelect) {
        this.setIndexArray([]);
      } else {
        this.setIndexArray([rowIndex]);
      }
    }
    return null;
  };

  toggleAddMaterialsToSampleModal = () => {
    this.setState({ addSampleModalVisible: !this.state.addSampleModalVisible });
  };
  fetchSamples = testID => {
    const { testTypeID } = this.props;
    this.props.fetchSamples(testID, testTypeID);
  };
  addMaterialsToSample = sampleID => {
    const materials = this.props.dataList
      .filter((material, index) => this.state.selectArray.indexOf(index) > -1)
      .map(material => material.materialID);
    const payload = {
      testID: this.props.testID,
      testTypeID: this.props.testTypeID,
      sampleID,
      materials,
      action: "add"
    };
    this.props.addMaterialsToSample(payload);
    this.toggleAddMaterialsToSampleModal();
  };

  saveNrOfPlants = () => {
    const { leafDiskMaterialMap } = this.props;

    const materialsUpdated = [];
    Object.keys(leafDiskMaterialMap).forEach(key => {
      if (leafDiskMaterialMap[key].changed) {
        const map = key.split("-");

        const nrOfPlants = leafDiskMaterialMap[`${map[0]}-#plants`]
          ? leafDiskMaterialMap[`${map[0]}-#plants`].newState || ""
          : "";

        materialsUpdated.push({
          materialID: map[0],
          nrOfPlants
        });
      }
    });

    const payload = {
      testID: this.props.testID,
      materials: materialsUpdated
    };
    this.props.updateMaterial(payload);
  };

  render() {
    const {
      testTypeID,
      colRecords,
      importLevel,
      leafDiskMaterialMap,
      dirty,
      statusCode,
      sampleType
    } = this.props;

    const ThreeGBType = testTypeID === 4 || testTypeID === 5;
    const s2sType = testTypeID === 6;
    const cAndTType = testTypeID === 7;
    // DNA save button and Mange DNA tab option remove as requeste
    const isDNA = testTypeID === 2;
    const leafDisk = testTypeID === 9;
    const isSeedHealth = testTypeID === 10;
    const s2sTypeAndMarkerStatusFalse =
      s2sType && this.props.markerstatus === false;
    const cAndTTypeAndMarkerStatusFalse =
      cAndTType && this.props.markerstatus === false;

    const isPlot = importLevel === "Plot";

    const disableUpdate = statusCode > 150;
    const displayAddSample = (leafDisk && isPlot) || (isSeedHealth && sampleType === "seedcluster"); 

    // flag for disabling save button in case of marker status is unchanged.
    const nrOfPlantsChanged =
      Object.keys(leafDiskMaterialMap).some(
        key => leafDiskMaterialMap[key].changed
      ) || dirty;

    return (
      <Fragment>
        <div>
          <Markers
            status={this.props.status}
            show={this.props.show}
            collapse={this.props.collapse}
            testTypeID={testTypeID}
            addToS2S={this.props.addToS2S}
            selectArray={this.state.selectArray}
          />
        </div>

        {ThreeGBType && (
          <div className="trow marker">
            <button
              onClick={this.addToThreeGBList}
              title="Add to 3GB"
              className="icon"
            >
              <i className="icon icon-ok-squared" />
              Add to 3GB
            </button>
          </div>
        )}
        {isDNA && (
          <div className="trow marker">
            <button
              onClick={this.addToThreeGBList}
              title="Add to Plate"
              className="icon"
            >
              <i className="icon icon-ok-squared" />
              Add to Plate
            </button>
          </div>
        )}
        {s2sTypeAndMarkerStatusFalse && (
          <div className="trow marker">
            <button title="Add to S2S" className="icon" onClick={this.addToS2S}>
              <i className="icon icon-ok-squared" />
              Add to S2S
            </button>
          </div>
        )}
        {cAndTTypeAndMarkerStatusFalse && (
          <div className="trow marker">
            <button title="Add to CNT" className="icon" onClick={this.addToS2S}>
              <i className="icon icon-ok-squared" />
              Add to C&T
            </button>
          </div>
        )}
        {displayAddSample && (
          <div className="trow marker">
            <button
              title="Add to Sample"
              className="icon"
              onClick={this.toggleAddMaterialsToSampleModal}
              disabled={this.state.selectArray.length === 0 || disableUpdate}
            >
              <i className="icon icon-plus-squared" />
              Add to Sample
            </button>
          </div>
        )}
        {leafDisk && !isPlot && (
          <div className="trow marker">
            <button
              title="Save"
              className="icon"
              onClick={this.saveNrOfPlants}
              disabled={!nrOfPlantsChanged || disableUpdate}
            >
              <i className="icon icon-floppy" />
              Save
            </button>
          </div>
        )}
        {this.state.addSampleModalVisible && (
          <AddMaterialsToSampleModal
            toggle={this.toggleAddMaterialsToSampleModal}
            addMaterialsToSample={this.addMaterialsToSample}
            fetchSamples={this.fetchSamples}
            samples={this.props.samples}
            testID={this.props.testID}
          />
        )}

        {colRecords ? (
          <TableData
            {...this.props}
            tableCellWidth={this.props.tblCellWidth}
            tblHeight={this.props.tblHeight}
            tblWidth={this.props.tblWidth}
            fixColumn={this.props.fixColumn}
            show={this.props.show}
            visibility={this.props.visibility}
            selectedChange={this.selectRow}
            selectArray={this.state.selectArray}
            setIndexArray={this.setIndexArray}
            leafDiskMaterialMap={this.props.leafDiskMaterialMap}
          />
        ) : (
          ""
        )}
        <Page
          testID={this.props.testID}
          testTypeID={this.props.testTypeID}
          pageNumber={this.props.pageNumber}
          pageSize={this.props.pageSize}
          records={this.props.records}
          filter={this.props.filter}
          onPageClick={this.props.onPageClick}
          isBlocking={false}
          isBlockingChange={() => {}}
          pageClicked={() => {}}
          _fixColumn={this.props._fixColumn}
          clearFilter={this.props.clearFilter}
          filterLength={this.props.filterLength}
          total={this.props.total}
        />
      </Fragment>
    );
  }
}
const mapStateToProps = state => ({
  sideMenu: state.sidemenuReducer,
  markerLength: state.assignMarker.marker.length,
  columnList: state.assignMarker.column,
  dataList: state.assignMarker.data,
  leafDiskMaterialMap: state.assignMarker.materials.leafDiskMaterialMap,
  scoreRefresh: state.assignMarker.materials.refresh,
  total: state.assignMarker.total,
  samples: state.assignMarker.samples.samples
});

const mapDispatchToProps = dispatch => ({
  fetchSamples: (testID, testTypeID) => dispatch({ type: "FETCH_SAMPLES", testID, testTypeID }),
  addMaterialsToSample: payload =>
    dispatch({ type: "ADD_MATERIAL_TO_SAMPLE", payload }),
  updateMaterial: payload =>
    dispatch({ type: "UPDATE_NROFPLANTS_MATERIAL", payload })
});
MarkerAssign.defaultProps = {
  testID: 0,
  pageNumber: 1,
  pageSize: 200,
  records: [],

  tblWidth: 0,
  tblHeight: 0,
  tblCellWidth: 0,
  testTypeID: 0,
  dataList: []
};
MarkerAssign.propTypes = {
  testID: PropTypes.number,
  pageNumber: PropTypes.number,
  pageSize: PropTypes.number,
  records: PropTypes.number, // eslint-disable-line
  filter: PropTypes.any, // eslint-disable-line
  onPageClick: PropTypes.func.isRequired,
  _fixColumn: PropTypes.any, // eslint-disable-line
  clearFilter: PropTypes.any, // eslint-disable-line
  filterLength: PropTypes.any, // eslint-disable-line
  visibility: PropTypes.any, // eslint-disable-line
  fixColumn: PropTypes.any, // eslint-disable-line

  tblWidth: PropTypes.number,
  tblHeight: PropTypes.number,
  tblCellWidth: PropTypes.number,
  collapse: PropTypes.any, // eslint-disable-line
  show: PropTypes.bool.isRequired,
  status: PropTypes.bool.isRequired,
  markerstatus: PropTypes.bool.isRequired,
  colRecords: PropTypes.any, // eslint-disable-line
  testTypeID: PropTypes.number,
  addToThreeGBList: PropTypes.func.isRequired,
  addToS2S: PropTypes.func.isRequired,
  dataList: PropTypes.array, // eslint-disable-line
  total: PropTypes.any, // eslint-disable-line
  addMaterialsToSample: PropTypes.func.isRequired,
  updateMaterial: PropTypes.func.isRequired,
  samples: PropTypes.arrayOf(
    PropTypes.shape({
      sampleID: PropTypes.number,
      sampleName: PropTypes.string
    })
  ).isRequired,
  fetchSamples: PropTypes.func.isRequired
};

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(MarkerAssign);
