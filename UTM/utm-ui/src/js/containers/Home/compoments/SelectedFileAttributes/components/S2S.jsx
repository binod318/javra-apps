import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import Dropdown from '../../../../../components/Combobox/Combobox';

function S2S(props) {
  const {
    testEditMode,
    testTypeID,
    testTypeList,
    handleTestTypeChange,
    cropCode,
    crops
  } = props;
  return (
    <div className="trow">
      <div className="tcell">
        <Dropdown
          disabled={!testEditMode}
          label="Test type"
          options={testTypeList}
          value={testTypeID}
          change={handleTestTypeChange}
        />
      </div>
      <div className="tcell">
        <div>
          <label>Crops</label>
          <select defaultValue={cropCode} disabled={!testEditMode}>
            <option>Select</option>
            {crops.map(c => (
              <option key={c} value={c}>
                {c}
              </option>
            ))}
          </select>
        </div>
      </div>
      <div className="tcell" />
      <div className="tcell" />
    </div>
  );
}

S2S.defaultProps = {
  testTypeList: [],
  crops: []
};
S2S.propTypes = {
  testEditMode: PropTypes.bool.isRequired,
  testTypeList: PropTypes.array, // eslint-disable-line
  crops: PropTypes.array, // eslint-disable-line
  handleTestTypeChange: PropTypes.func.isRequired,
  testTypeID: PropTypes.number.isRequired,
  cropCode: PropTypes.string.isRequired
};

const mapStateToProps = state => ({
  crops: state.user.crops,
  breedingStation: state.breedingStation.station,
  capacitySlotList: state.assignMarker.s2sCapacitySlot
});
export default connect(
  mapStateToProps,
  null
)(S2S);
