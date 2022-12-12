import React, { Component } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';

class Export extends Component {
  constructor(props) {
    super(props);
    this.state = {
      cropSelected: props.cropSelected,
      breedingStation: props.breedingStationSelected,
      exportList: [],
      exportFile: '',
      fileName: '',
      traitscore: false
    };
  }

  componentDidMount() {
    const { cropSelected, breedingStationSelected } = this.props;
    if (cropSelected !== '' && breedingStationSelected !== '') {
      this.fetch(cropSelected, breedingStationSelected);
    }
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.exportList) {
      this.setState({
        exportList: nextProps.exportList
      });
    }
  }

  handleChange = ({ target }) => {
    const {
      cropSelected,
      breedingStation,
      exportList,
      traitscore
    } = this.state;
    const { type, name, value } = target;

    if (type === 'radio') {
      this.setState({
        traitscore: !traitscore
      });
      return null;
    }
    this.setState({
      [name]: value
    });

    const cropCondition = cropSelected !== '' && name === 'breedingStation';
    const breedCondition = breedingStation !== '' && name === 'cropSelected';

    if (name !== 'exportFile') {
      if (cropCondition) {
        this.fetch(cropSelected, value);
      }
      if (breedCondition) {
        this.fetch(value, breedingStation);
      }
    } else {
      const saveName = exportList.find(n => n.testID == value).testName || name; // eslint-disable-line
      this.setState({
        fileName: [saveName]
      });
    }
    return null;
  };

  fetch = (cropCode, brStationCode) => {
    this.props.fetchExternalTests({ cropCode, brStationCode });
  };

  downFile = mark => {
    const { exportFile: testID, fileName, traitscore } = this.state;
    this.props.exportTest(testID, mark, fileName, traitscore);
    this.props.close();
  };

  validate = () => this.state.exportFile === '';

  render() {
    const {
      cropSelected,
      breedingStation,
      exportList,
      exportFile,
      traitscore
    } = this.state;
    const { breedingStation: blist, crops } = this.props;
    return (
      <div className="slot-file-modal">
        <div className="slot-file-modal-content">
          <div className="slot-file-modal-title">
            <span
              onKeyDown={() => {}}
              className="slot-file-modal-close"
              onClick={this.props.close}
              tabIndex="0"
              role="button"
            >
              &times;
            </span>
            <span> Export to Excel</span>
          </div>
          <div className="slot-file-modal-body">
            <label htmlFor="cropSelected">
              Crops
              <select
                name="cropSelected"
                value={cropSelected}
                onChange={this.handleChange}
              >
                <option value="">Select</option>
                {crops.map(c => (
                  <option key={c} value={c}>
                    {c}
                  </option>
                ))}
              </select>
            </label>
            <label htmlFor="breedingStation">
              Br.Station
              <select
                name="breedingStation"
                value={breedingStation}
                onChange={this.handleChange}
              >
                <option value="">Select</option>
                {blist.map(b => (
                  <option
                    key={b.breedingStationCode}
                    value={b.breedingStationCode}
                  >
                    {b.breedingStationCode}
                  </option>
                ))}
              </select>
            </label>
            <br />
            <br />
            <label htmlFor="exportFile">
              Export File List
              <select
                name="exportFile"
                value={exportFile}
                onChange={this.handleChange}
              >
                <option value="">Select</option>
                {exportList.map(b => (
                  <option key={b.testID} value={b.testID}>
                    {b.testName}
                  </option>
                ))}
              </select>
            </label>

            <div className="exportscore">
              <input
                type="radio"
                id="markerScore"
                name="traitscore"
                onChange={this.handleChange}
                value="Marker Score"
                checked={!traitscore}
              />
              <label htmlFor="markerScore">Marker Score</label>
              <input
                type="radio"
                id="traitScore"
                name="traitscore"
                onChange={this.handleChange}
                value="Trait Score"
                checked={traitscore}
              />
              <label htmlFor="traitScore">Trait Score</label>
            </div>
          </div>
          <div className="slot-file-modal-footer">
            &nbsp;
            <button
              onClick={() => this.downFile(true)}
              disabled={this.validate()}
            >
              Export
            </button>
          </div>
        </div>
      </div>
    );
  }
}
Export.defaultProps = {
  breedingStation: [],
  crops: [],
  exportList: [],
  cropSelected: '',
  breedingStationSelected: ''
};
Export.propTypes = {
  breedingStation: PropTypes.array, // eslint-disable-line
  crops: PropTypes.array, // eslint-disable-line
  exportList: PropTypes.array, // eslint-disable-line
  close: PropTypes.func.isRequired,
  exportTest: PropTypes.func.isRequired,
  fetchExternalTests: PropTypes.func.isRequired,
  cropSelected: PropTypes.string,
  breedingStationSelected: PropTypes.string
};
const mapStateToProps = state => ({
  crops: state.user.crops,
  breedingStation: state.breedingStation.station,
  exportList: state.exportList,
  cropSelected: state.user.selectedCrop,
  breedingStationSelected: state.breedingStation.selected
});
const mapDispatchProps = dispatch => ({
  fetchExternalTests: obj => dispatch({ type: 'FETCH_EXTERNAL_TESTS', ...obj }),
  exportTest: (testID, mark, fileName, traitscore) =>
    dispatch({
      type: 'EXPORT_EXTERNAL_TEST',
      testID,
      mark,
      fileName,
      TraitScore: traitscore
    })
});
export default connect(
  mapStateToProps,
  mapDispatchProps
)(Export);
