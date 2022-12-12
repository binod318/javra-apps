import React from 'react';
import PropTypes from 'prop-types';

function Exist({ objectID }) {
  return (
    <div>
      <label htmlFor="objectID">
        Selected Object ID
        <input name="objectID" type="text" value={objectID} readOnly disabled />
      </label>
    </div>
  );
}

Exist.defaultProps = {};
Exist.propTypes = {
  objectID: PropTypes.string.isRequired
};
export default Exist;
