import React from 'react';
import PropTypes from 'prop-types';

import './wrapper.scss';

const Wrapper = ({ children, display }) => {
  if (display === '') return null;
  // if (display === null) return null;
  return <div className="wrapper">{children}</div>;
};

Wrapper.defaultProps = { display: null };
Wrapper.propTypes = {
  children: PropTypes.object.isRequired, // eslint-disable-line
  display: PropTypes.any  // eslint-disable-line
};
export default Wrapper;
