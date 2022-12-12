import React, { Fragment } from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import DateInput from '../../../../../components/DateInput';
import Dropdown from '../../../../../components/Combobox/Combobox';

function SeedHealth(props) {
  const {
    testEditMode,

    testTypeID,
    testTypeList,
    handleTestTypeChange,

    siteID,
    sites,
    handleLabLocationChange,

    sampleType,
    handleSampleTypeChange

  } = props;

  const sampleTypeOptions = [
    { sampleTypeCode: 'fruit', sampleTypeName: 'Fruit sample' },
    { sampleTypeCode: 'seedcluster', sampleTypeName: 'Seed sample cluster' },
    { sampleTypeCode: 'seedsmall', sampleTypeName: 'Seed sample small' }
  ]

  return (
    <Fragment>
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
          <Dropdown
            disabled={!testEditMode}
            label="Site Location"
            options={sites}
            value={siteID}
            change={handleLabLocationChange}
          />
        </div>
        <div className="tcell">
          <Dropdown
            disabled
            label="Sample Type"
            options={sampleTypeOptions}
            value={sampleType}
            change={handleSampleTypeChange}
          />
        </div>
      </div>
    </Fragment>
  );
}

SeedHealth.defaultProps = {
  testTypeList: [],
  sites: []
};
SeedHealth.propTypes = {
  testEditMode: PropTypes.bool.isRequired,

  testTypeList: PropTypes.array, // eslint-disable-line
  sites: PropTypes.array,

  handleTestTypeChange: PropTypes.func.isRequired,
  handleLabLocationChange: PropTypes.func.isRequired,
  handleSampleTypeChange: PropTypes.func.isRequired,

  testTypeID: PropTypes.number.isRequired,
  siteID: PropTypes.number,
  sampleType: PropTypes.string
};

export default SeedHealth;
