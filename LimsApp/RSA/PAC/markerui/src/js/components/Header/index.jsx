import React from "react";
import { withRouter } from "react-router-dom"; // NavLink,
import { connect } from "react-redux";
import PropTypes from "prop-types";
import { sidemenuToggle } from "../../action";
import "./header.scss";

const Header = ({ sideStatus, onclick, user }) => (
  <header>
    <div className={!sideStatus ? "headBar" : "headBar active"}>
      <div className='title'>PAC</div>
      <nav>
        <div className='user' title={window.userContext.name}>
          <i className='icon icon-user' />
          <span>{user}</span>
        </div>
      </nav>
    </div>
  </header>
);

const mapStateToProps = (state) => ({
  sideStatus: state.sidemenuReducer,
  role: state.user.role,
  user: state.user.name,
});
const mapDispatchToProps = (dispatch) => ({
  onclick: () => dispatch(sidemenuToggle()),
});

Header.propTypes = {
  sideStatus: PropTypes.bool.isRequired,
  onclick: PropTypes.func.isRequired,
};
export default withRouter(connect(mapStateToProps, mapDispatchToProps)(Header));
