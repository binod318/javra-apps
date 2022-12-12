import React, { Fragment } from "react";
import { connect } from "react-redux";
import PropTypes from "prop-types";

import Aside from "../Aside";
import Header from "../Header";
import { sidemenuToggle } from "../../action";

const PublicLayout = ({ children, onclick, sideStatus }) => (
  <Fragment>
    <Aside onclick={onclick} sideStatus={sideStatus} />
    <div className='bodyWrap'>
      <Header />
      <div>
        <div className='main'>{children}</div>
      </div>
    </div>
  </Fragment>
);

const mapStateToProps = (state) => ({
  sideStatus: state.sidemenuReducer,
});
const mapDispatchToProps = (dispatch) => ({
  resetAll: () => dispatch({ type: "RESETALL" }),
  onclick: () => dispatch(sidemenuToggle()),
});

PublicLayout.propTypes = {
  sideStatus: PropTypes.bool.isRequired,
  onclick: PropTypes.func.isRequired,
  children: PropTypes.object.isRequired, // eslint-disable-line
};
export default connect(mapStateToProps, mapDispatchToProps)(PublicLayout);
// export default Layout;
