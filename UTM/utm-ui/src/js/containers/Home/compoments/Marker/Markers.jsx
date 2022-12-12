import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import autoBind from 'auto-bind';
import { markerToggle, markerAssign } from './markerAction';
import { checkStatus } from '../../../../helpers/helper';
import Marker from './Marker';
import {
  saveS2SMarkerMaterial,
  saveCNTMarkerMaterial
} from '../ManageMarkers/components/actions';

class Markers extends React.Component {
  constructor(props) {
    super(props);
    autoBind(this);
  }
  preAssignMarker() {
    const { testID, testTypeID, filter } = this.props;
    const determinationsChecked = [];
    this.props.markers.map(d => {
      if (d.selected === true) determinationsChecked.push(d.determinationID);
      return null;
    });

    /**
     * 6600 - UTM: Improve grid selection options in UTM - assign markers
     * If row selection exists makes a different call.
     */
    if (this.props.selectArray.length) {
      const { dataList, selectArray } = this.props;
      const materialIDFromSelectedArray = selectArray.map(selectedObj => {
        const { materialID } = dataList[selectedObj];
        return {
          materialID,
          selected: true
        };
      });
      /**
       * A new service was introduct just to meet the requirement
       * of rows selection and assign markers.
       */
      if (testTypeID === 6) {
        const postData = [];
        materialIDFromSelectedArray.forEach(selectedObj => {
          determinationsChecked.forEach(determinationID => {
            postData.push({ ...selectedObj, determinationID });
          });
        });
        const objMarker = { testID, details: postData };
        this.props.saveS2SChangeSelectionRows(objMarker);
        return null;
      }
      if (testTypeID === 7) {
        const postData = [];
        materialIDFromSelectedArray.forEach(selectedObj => {
          determinationsChecked.forEach(determinationID => {
            postData.push({ ...selectedObj, determinationID });
          });
        });
        const objMarker = {
          testID,
          markers: postData,
          materials: [],
          details: []
        };
        this.props.saveCNTChangeSelectingRows(objMarker);
        return null;
      }
      const postData = [];

      //When there is two traits linked to one determinations, send only one determination to db
      const unique = (value, index, self) => {
        return self.indexOf(value) === index
      }
      const uniqueDeterminations = determinationsChecked.filter(unique)

      materialIDFromSelectedArray.forEach(selectedObj => {
        uniqueDeterminations.forEach(determinationID => {
          postData.push({ ...selectedObj, determinationID });
        });
      });
      const objMarker = {
        testID,
        testTypeID,
        materialWithMarker: postData
      };
      this.props.otherSaveSelectingRows(objMarker);
      return null;
    }

    if (testTypeID === 6) {
      this.props.saveMarkerMaterial(
        testID,
        testTypeID,
        filter,
        determinationsChecked
      );
    } else if (testTypeID === 7) {
      this.props.saveCNTMaterial(
        testID,
        testTypeID,
        filter,
        determinationsChecked
      );
    } else if (testTypeID === 8) {
      this.props.saveRDTMaterial(
        testID,
        testTypeID,
        filter,
        determinationsChecked
      );
    } else {
      this.props.assignMarker(
        testID,
        testTypeID,
        filter,
        determinationsChecked
      );
    }
    return null;
  }

  perAddTo() {
    if (this.props.selectArray.length) {
      const { dataList, selectArray } = this.props;
      const materialIDFromSelectedArray = selectArray.map(selectedObj => {
        const { materialKey } = dataList[selectedObj];
        return { materialKey, selected: true };
      });
      this.props.addToS2S(materialIDFromSelectedArray);
      return null;
    }
    this.props.addToS2S();
    return null;
  }

  render() {
    const btnStat = checkStatus(this.props.statusCode, 'CONFIRM');
    const {
      status,
      show,
      markers,
      collapse,
      toggleClick,
      testTypeID
    } = this.props;
    if (!status) return null;
    const assignChecked = markers.some(mark => mark.selected === true);
    const showAddBtn = testTypeID === 6 || testTypeID === 7;
    const btnName = testTypeID === 6 ? 'S2S' : 'C&T';

    return (
      <div className="trow marker">
        <div className="tcell">
          <div className="markTitle">
            <button
              onClick={this.preAssignMarker}
              disabled={btnStat || !assignChecked}
              id="assign_marker_btn"
              title="Assign marker"
              className="icon"
            >
              <i className="icon icon-ok-squared" />
              {testTypeID === 8 ? 'Assign Test' : 'Assign Marker'}
            </button>
            {/* <button disabled={btnStat || !assignChecked} onClick={this.props.diselect}>Uncheck All</button> */}
            {showAddBtn && (
              <button title={`Add to ${btnName}`} onClick={this.perAddTo}>
                Add to {btnName}
              </button>
            )}
            {/* <button onClick={this.props.goto} disabled={!gotoCheck} title="Plate filling">Plate Filling</button> */}
            <button
              className="visible"
              title="Toggle marker"
              onClick={collapse}
            >
              <i
                className={show ? 'icon icon-up-open' : 'icon icon-down-open'}
              />
            </button>
          </div>

          {show ? (
            <div className="markContainer">
              {markers.map(mark => (
                <Marker
                  key={`${mark.determinationID}_${
                    mark.columnLabel}_${Math.random * 100}`} /* eslint-disable-line */
                  {...mark}
                  onChange={() => toggleClick(mark.determinationID)}
                />
              ))}
            </div>
          ) : (
            ''
          )}
        </div>
      </div>
    );
  }
}
const mapStateToProps = (state, ownProps) => ({
  markers: state.assignMarker.marker,
  testID: state.rootTestID.testID,
  testTypeID: state.assignMarker.testType.selected,
  statusCode: state.rootTestID.statusCode,
  filter: state.assignMarker.filter,
  status: ownProps.status,
  show: ownProps.show,
  collapse: ownProps.collapse,
  dataList: state.assignMarker.data
});
const mapDispatchToProps = dispatch => ({
  toggleClick: id => dispatch(markerToggle(id)),
  // diselect: () => dispatch({ type: 'MARKER_DISELECT' }),
  assignMarker: (testID, testTypeID, filter, determinationsChecked) => {
    dispatch(markerAssign(testID, testTypeID, filter, determinationsChecked));
  },
  saveMarkerMaterial: (testID, testTypeID, filter, determinationsChecked) => {
    const obj = {
      testID,
      testTypeID,
      filter,
      determinations: determinationsChecked
    };
    dispatch(saveS2SMarkerMaterial(obj));
  },
  saveS2SChangeSelectionRows: obj => {
    // alert(456);
    dispatch({ type: 'POST_S2S_ASSIGN_MARKER_WITH_SELECTION_ROW', ...obj });
  },
  saveCNTMaterial: (testID, testTypeID, filter, determinationsChecked) => {
    const obj = {
      testID,
      testTypeID,
      filter,
      determinations: determinationsChecked
    };
    dispatch(saveCNTMarkerMaterial(obj));
  },
  saveRDTMaterial: (testID, testTypeID, filter, determinationsChecked) => {
    const materialsMarkers = {
      testID,
      testTypeID,
      filter,
      determinations: determinationsChecked
    };
    dispatch({ type: 'SAVE_RDT_MATERIAL_MARKER', materialsMarkers });
  },
  saveCNTChangeSelectingRows: obj =>
    dispatch({ type: 'POST_CNT_MANAGE_MARKERS', ...obj }),
  otherSaveSelectingRows: materialsMarkers => {
    dispatch({ type: 'SAVE_MATERIAL_MARKER', materialsMarkers });
  }
});
Markers.defaultProps = {
  dataList: [],
  selectArray: [],
  statusCode: null,
  testTypeID: null,
  testID: null
};
Markers.propTypes = {
  addToS2S: PropTypes.func.isRequired,
  saveRDTMaterial: PropTypes.func.isRequired,
  saveCNTMaterial: PropTypes.func.isRequired,
  saveMarkerMaterial: PropTypes.func.isRequired,
  otherSaveSelectingRows: PropTypes.func.isRequired,
  saveCNTChangeSelectingRows: PropTypes.func.isRequired,
  saveS2SChangeSelectionRows: PropTypes.func.isRequired,
  dataList: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  selectArray: PropTypes.array, // eslint-disable-line react/forbid-prop-types

  markers: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  filter: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  statusCode: PropTypes.number,
  testID: PropTypes.number,
  testTypeID: PropTypes.number,
  assignMarker: PropTypes.func.isRequired,
  toggleClick: PropTypes.func.isRequired,
  collapse: PropTypes.func.isRequired,
  status: PropTypes.bool.isRequired,
  show: PropTypes.bool.isRequired
};
export default connect(
  mapStateToProps,
  mapDispatchToProps
)(Markers);
