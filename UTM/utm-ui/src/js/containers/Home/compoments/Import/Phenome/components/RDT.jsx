import React, { Fragment } from 'react';
import PropTypes from 'prop-types';
// import DateInput from '../../../../../../components/DateInput';

function RDT(props) {
  const { importLevel, sites, siteID } = props;

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
        <label>Import Level</label>
        <div className="radioSection">
          <label
            htmlFor="plant"
            className={importLevel === 'PLT' ? 'active' : ''}
          >
            <input
              id="plant"
              type="radio"
              value="PLT"
              name="importLevel"
              checked={importLevel === 'PLT'}
              onChange={props.handleChange}
            />
            Plant
          </label>
          <label
            htmlFor="list"
            className={importLevel === 'LIST' ? 'active' : ''}
          >
            <input
              id="list"
              type="radio"
              value="LIST"
              name="importLevel"
              checked={importLevel === 'LIST'}
              onChange={props.handleChange}
            />
            List
          </label>
        </div>
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

RDT.defaultProps = {
  siteID: 0,
  sites: [],
  fileName: ''
};
RDT.propTypes = {
  siteID: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  importLevel: PropTypes.string.isRequired,
  sites: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  handleChange: PropTypes.func.isRequired,
  objectID: PropTypes.string.isRequired,
  fileName: PropTypes.string
};
export default RDT;
