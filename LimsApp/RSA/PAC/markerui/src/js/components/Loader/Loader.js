import React from "react";
import { connect } from "react-redux";
import PropTypes from "prop-types";
import "./loader.scss";

export const myLoader = ({ status }) => {
  if (status <= 0) {
    return <span />;
  }

  return (
    <div className='loaderWrapper active' id='loader'>
      <div className='loader'>
        <i className='demo-icon icon-spin6 animate-spin' />
      </div>
    </div>
  );
};

const mapStateToProps = (state) => ({
  status: state.loader,
});

myLoader.defaultProps = {
  status: 0,
};
myLoader.propTypes = {
  status: PropTypes.number,
};
const Loader = connect(mapStateToProps, null)(myLoader);
export default Loader;
