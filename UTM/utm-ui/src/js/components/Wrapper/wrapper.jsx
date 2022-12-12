import React from 'react';
import PropTypes from 'prop-types';
import './wrapper.scss';

const Wrapper = ({ children }) => <div className="Wrapper">{children}</div>;

Wrapper.propTypes = {
  children: PropTypes.object // eslint-disable-line
};
export default Wrapper;
