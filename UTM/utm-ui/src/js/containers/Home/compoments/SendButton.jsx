import React from 'react';
import PropTypes from 'prop-types';

const SendButton = ({ title, action, text, icon, status }) => (
  <button
    title={title}
    onClick={action}
    className="with-i"
    icon={icon}
    disabled={status !== 0}
  >
    <i className={`icon ${icon}`} />
    <span>{text}</span>
  </button>
);
SendButton.defaultProps = {
  title: '',
  action: () => {},
  text: '',
  icon: 'icon-paper-plane',
  status: 0
};
SendButton.propTypes = {
  title: PropTypes.string,
  action: PropTypes.func,
  text: PropTypes.string,
  icon: PropTypes.string,
  status: PropTypes.number
};
export default SendButton;
