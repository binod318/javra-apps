import React from "react";
import { withRouter } from "react-router-dom"; // NavLink,
import { connect } from "react-redux";
import PropTypes from "prop-types";
import "./header.scss";
import { adalUserInfo } from "../../config/adal";

const userInfo = adalUserInfo();
const username = userInfo ? userInfo.profile.name : "";
const Header = ({ sideStatus }) => (
  <header>
    <div className={!sideStatus ? "headBar" : "headBar active"}>
      <div className="title">UTM</div>
      <nav>
        <div className="user" title={username}>
          <i className="icon icon-user" />
          <span>{username}</span>
        </div>
      </nav>
    </div>
  </header>
);

const mapStateToProps = state => ({
  sideStatus: state.sidemenuReducer,
  role: state.user.role,
  testTypeID: state.rootTestID.testTypeID
});
const mapDispatchToProps = dispatch => ({});

Header.propTypes = {
  sideStatus: PropTypes.bool.isRequired
};
export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(Header)
);
