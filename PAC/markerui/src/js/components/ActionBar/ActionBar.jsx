import React from 'react';
import PropTypes from 'prop-types';

function ActionBar(props) {
  return (
    <section className="page-action">
      <div className="left">{props.left()}</div>
      <div className="right">{props.right()}</div>
    </section>
  );
}

ActionBar.defaultProps = {
  left: () => {},
  right: () => {}
};
ActionBar.propTypes = {
  left: PropTypes.func,
  right: PropTypes.func
};
export default ActionBar;
