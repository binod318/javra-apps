import React from 'react';
import PropTypes from 'prop-types';
import './wrapper.scss';

export const myWrapper = ({ children }) => <div className="Wrapper">{children}</div>;

myWrapper.propTypes = {
  children: PropTypes.object // eslint-disable-line
};
const Wrapper = myWrapper;
export default Wrapper;
