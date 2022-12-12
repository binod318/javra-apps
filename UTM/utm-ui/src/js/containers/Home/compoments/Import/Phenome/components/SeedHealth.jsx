import React, { Fragment } from 'react';
import PropTypes from 'prop-types';

function SeedHealth(props) {
  const { sites, siteID, sampleType } = props;

  return (
    <Fragment>
      <div className="gridTwoCell">
        <label htmlFor="siteID">
          Site Location
          <select
            name="siteID"
            onChange={props.handleChange}
            value={siteID}
          >
            <option value="">Select</option>
            {sites.map(({ siteID, siteName }) => (
              <option value={siteID} key={siteID}> {/* eslint-disable-line */}
                {siteName}
              </option>
            ))}
          </select>
        </label>
      </div>

      <div>
        <label htmlFor="sampleType">
          Sample Type
          <select
            name="sampleType"
            onChange={props.handleChange}
            value={sampleType}
          >
            <option value="">Select</option>
            <option value="fruit">Fruit sample</option>
            <option value="seedcluster">Seed sample cluster</option>
            <option value="seedsmall">Seed sample small</option>

          </select>
        </label>
      </div>

      <div>
        <label htmlFor="objectID">
          Selected Object ID
          <input
            name="objectID"
            type="text"
            value={props.objectID}
            readOnly
            disabled
          />
        </label>
      </div>

      <div>
        <label htmlFor="fileName">
          File Name
          <input
            name="fileName"
            type="text"
            value={props.fileName}
            onChange={props.handleChange}
            disabled={false}
          />
        </label>
      </div>
    </Fragment>
  );
}

SeedHealth.defaultProps = {
  siteID: 0,
  sampleType: '',
  sites: [],
  fileName: ''
};
SeedHealth.propTypes = {
  siteID: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  sampleType: PropTypes.string,
  importLevel: PropTypes.string.isRequired,
  sites: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  handleChange: PropTypes.func.isRequired,
  objectID: PropTypes.string.isRequired,
  fileName: PropTypes.string
};
export default SeedHealth;
