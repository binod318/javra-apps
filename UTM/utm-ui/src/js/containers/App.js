import React from "react";
import { BrowserRouter, Switch } from "react-router-dom";
import { connect } from "react-redux";
import PropTypes from "prop-types";
// this one is not in route
import PrintList from "./PunchList/PunchList";
import LDPunchList from "./LDPunchList/LDPunchList";
import NoMatch from "./NoMatch";
import Loader from "../components/Loader/Loader";
import Remarks from "../components/Remarks/Remark";
import AppError from "../components/Error";
import Notification from "../components/Notification/Notification";
import ManageRDTprint from "./Home/compoments/ManageMarkers/components/ManageRDTprint";
import PrivateRoute from "../components/Private";
import "../helpers/axiosInterceptor";
import { couputeRoute } from "../routes";
import { adalUserInfo } from "../config/adal";
import Aside from "../components/Aside";

class App extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      tblCellWidth: 100,
      tblWidth: 1100,
      tblHeight: 500,
      login: false
    };
  }
  componentDidMount() {
    const userInfo = adalUserInfo();
    const roles = userInfo ? userInfo.profile.roles : [];
    this.props.setRoles(roles);
    this.props.fetchUserCrops();
  }

  resize = () => {
    const width = window.innerWidth;
    this.setState({
      tblWidth: width,
      tableHeight: window.document.body.offsetHeight
    });
  };

  setMenu = (menu) => {
    this.props.setSelectedMenu(menu);
  }

  render() {
    const { sideStatus, role, testTypeID } = this.props;
    if (role.length === 0) return null;
    const newComp = couputeRoute(role, testTypeID);
    return (
      <BrowserRouter>
        <div className="base" data-aside={sideStatus}>
          <Aside onclick={this.props.toggleSidemenu} setMenu={this.setMenu} sideStatus={sideStatus} />
          <Switch>
            {newComp.map((x, i) => (
              <PrivateRoute
                key={x.index}
                exact
                path={i === 0 ? "/" : x.to}
                component={x.comp}
              />
            ))}
            <PrivateRoute exact path="/punchlist" component={PrintList} />
            <PrivateRoute exact path="/samplelist" component={PrintList} />
            <PrivateRoute exact path="/ld-punchlist" component={LDPunchList} />
            <PrivateRoute component={NoMatch} />
          </Switch>
          <Loader />
          <Notification />
          <AppError {...this.state} close={this._errorClose} />
          <Remarks />
          <ManageRDTprint />
        </div>
      </BrowserRouter>
    );
  }
}

const mapStateToProps = state => ({
  sideStatus: state.sidemenuReducer,
  role: state.user.role,
  testTypeID: state.rootTestID.testTypeID
});
const mapDispatchToProps = dispatch => ({
  resetAll: () => dispatch({ type: "RESETALL" }),
  fetchUserCrops: () => dispatch({ type: "FETCH_USER_CROPS" }),
  setRoles: roles => dispatch({ type: "SET_ROLES", roles }),
  toggleSidemenu: () => dispatch({ type: "TOGGLE_SIDEMENU" }),
  setSelectedMenu: (menu) => dispatch({ type: "SET_SELECTEDMENU", menu })
});
App.defaultProps = {
  role: [],
  testTypeID: 0
};
App.propTypes = {
  resetAll: PropTypes.func.isRequired,
  testTypeID: PropTypes.number,
  sideStatus: PropTypes.bool.isRequired,
  role: PropTypes.oneOfType([PropTypes.string, PropTypes.array]), // eslint-disable-line react/forbid-prop-types
  fetchUserCrops: PropTypes.func.isRequired,
  setRoles: PropTypes.func.isRequired,
  toggleSidemenu: PropTypes.func.isRequired
};
export default connect(
  mapStateToProps,
  mapDispatchToProps
)(App);
