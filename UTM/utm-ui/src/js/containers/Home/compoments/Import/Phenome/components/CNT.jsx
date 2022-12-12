import React, { Fragment } from 'react';
import PropTypes from 'prop-types';
// import DateInput from '../../../../../../components/DateInput';

function CNT(props) {
  const { importLevel, cropSelected } = props;

  return (
    <Fragment>
      <div>
        <label htmlFor="cropSelected">
          Crops
          <select
            name="cropSelected"
            onChange={props.handleChange}
            value={cropSelected}
          >
            <option value="">Select</option>
            {props.crops.map(c => (
              <option value={c} key={c}>
                {c}
              </option>
            ))}
          </select>
        </label>
      </div>
      <div />

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

CNT.defaultProps = {
  crops: [],
  fileName: ''
};
CNT.propTypes = {
  importLevel: PropTypes.string.isRequired,
  crops: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  handleChange: PropTypes.func.isRequired,
  objectID: PropTypes.string.isRequired,
  fileName: PropTypes.string
};
export default CNT;
