import React from "react";
import { BrowserRouter, Switch } from "react-router-dom";
import { connect } from "react-redux";
import PropTypes from "prop-types";
import axios from "axios";

import { adalUserInfo, authContext } from "../config/adal";
import NoMatch from "./NoMatch";

import Loader from "../components/Loader/Loader";
import AppError from "../components/Error";
import Notification from "../components/Notification/Notification";

import PrivateRoute from "../components/Private";
import { couputeRoute } from "../routes";

import { AppInsightsContext } from '@microsoft/applicationinsights-react-js';
import { reactPlugin } from '../config/app-insights-service';

// add Authorization header with Bearer Token in each reqeust
axios.interceptors.request.use(
  function(config) {
    // Do something before request is sent
    return new Promise((resolve, reject) => {
      authContext.acquireToken(
        adalConfig.endpoints.api,
        (message, token, msg) => {
          if (!!token) {
            config.headers.Authorization = `Bearer ${token}`;
            resolve(config);
          } else {
            // Do something with error of acquiring the token
            reject(config);
          }
        }
      );
    });
  },
  function(error) {
    // Do something with request error
    return Promise.reject(error);
  }
);
const styles = {
  initLoader: {
    background: "rgba(0, 0, 0, 0.34)",
    height: "100%",
    display: "flex",
    justifyContent: "center",
    alignItems: "center",
  },
  loader: {
    width: "60px",
    height: "60px",
    background: "#fff",
    justifyContent: "center",
    alignItems: "center",
    display: "flex",
    borderRadius: "100%",
  },
};

class App extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      tblCellWidth: 100,
      tblWidth: 1100,
      tblHeight: 500,
      login: false,
    };
  }
  componentDidMount() {
    const userInfo = adalUserInfo();
    const data = {
      roles: userInfo.profile.roles,
      name: userInfo.profile.name,
    };
    this.props.setRoles(data);
  }

  resize = () => {
    const width = window.innerWidth;
    this.setState({
      tblWidth: width,
      tableHeight: window.document.body.offsetHeight,
    });
  };

  render() {
    const { sideStatus, role, token } = this.props;

    const newComp = couputeRoute(role);
    return (
      <AppInsightsContext.Provider value={reactPlugin}>
        <BrowserRouter>
          <div className='base' data-aside={sideStatus}>
            <Switch>
              {newComp.map((x, i) => (
                <PrivateRoute
                  key={x.index}
                  exact
                  path={i === 0 ? "/" : x.to}
                  component={x.comp}
                />
              ))}
              <PrivateRoute component={NoMatch} />
            </Switch>
            <Loader />
            <Notification />
            <AppError {...this.state} close={this._errorClose} />
          </div>
        </BrowserRouter>
      </AppInsightsContext.Provider>
    );
  }
}

const mapStateToProps = (state) => ({
  sideStatus: state.sidemenuReducer,
  role: state.user.role,
  token: state.user.token,
});
const mapDispatchToProps = (dispatch) => ({
  resetAll: () => dispatch({ type: "RESETALL" }),
  setRoles: (data) => dispatch({ type: "SET_ROLES", data }),
});
App.defaultProps = {
  role: [],
  testTypeID: 0,
};
App.propTypes = {
  resetAll: PropTypes.func.isRequired,
  testTypeID: PropTypes.number,
  sideStatus: PropTypes.bool.isRequired,
  role: PropTypes.oneOfType([PropTypes.string, PropTypes.array]), // eslint-disable-line react/forbid-prop-types
};
export default connect(mapStateToProps, mapDispatchToProps)(App);
