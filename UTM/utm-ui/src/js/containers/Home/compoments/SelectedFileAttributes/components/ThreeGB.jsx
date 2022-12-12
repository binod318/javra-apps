import React from 'react';
import PropTypes from 'prop-types';
import Dropdown from '../../../../../components/Combobox/Combobox';

function ThreeGB(props) {
  const {
    testEditMode,
    testTypeID,
    testTypeList,
    handleTestTypeChange,
    testID,
    fileList,
    containerTypeList,
    containerTypeID,
    handleContainerTypeChange
  } = props;

  // !testEditMode || testTypeID === 4
  return (
    <div className="trow">
      <div className="tcell">
        <Dropdown
          disabled
          label="Test type"
          options={testTypeList}
          value={testTypeID}
          change={handleTestTypeChange}
        />
      </div>
      <div className="tcell">
        <div>
          <label>Project List</label>
          <select defaultValue={testID} disabled>
            {fileList.map(f => (
              <option key={`${f.testID}-p`}>{f.fileTitle}</option>
            ))}
          </select>
        </div>
      </div>
      <div className="tcell">
        <Dropdown
          disabled={!testEditMode}
          label="Container Type"
          options={containerTypeList}
          value={containerTypeID}
          change={handleContainerTypeChange}
        />
      </div>
    </div>
  );
}

ThreeGB.defaultProps = {
  testTypeList: [],
  materialTypeList: [],
  materialStateList: [],
  containerTypeList: [],
  fileList: []
};
ThreeGB.propTypes = {
  testEditMode: PropTypes.bool.isRequired,

  todayDate: PropTypes.object, // eslint-disable-line

  testTypeList: PropTypes.array, // eslint-disable-line
  materialTypeList: PropTypes.array, // eslint-disable-line
  materialStateList: PropTypes.array, // eslint-disable-line
  containerTypeList: PropTypes.array, // eslint-disable-line
  fileList: PropTypes.array, // eslint-disable-line

  handleTestTypeChange: PropTypes.func.isRequired,
  handleContainerTypeChange: PropTypes.func.isRequired,

  testID: PropTypes.number.isRequired,
  testTypeID: PropTypes.number.isRequired,
  containerTypeID: PropTypes.number.isRequired
};

export default ThreeGB;
