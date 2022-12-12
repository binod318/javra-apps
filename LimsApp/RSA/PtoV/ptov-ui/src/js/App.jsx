import React from "react";
import { connect } from "react-redux";
import { BrowserRouter as Router, Switch, Route } from "react-router-dom";
import shortid from "shortid";
import PropTypes from "prop-types";
import "fixed-data-table-2/dist/fixed-data-table.css";
import "../styles/index.scss";

import Nav from "./components/Nav";
import NoMatch from "./containers/nomatch";
import RouteWithSubRoutes from "./components/RouteWithSubRoutes";
import { couputeRoute } from "./routes";
import { adalUserInfo } from "../js/config/adal";
import "./utils/axiosInterceptor";

const App = ({ fetchUserCrops }) => {
  const userInfo = adalUserInfo();
  const { roles } = userInfo.profile;
  fetchUserCrops();

  return (
    <Router>
      <div>
        <div>
          <Nav />
          <div className="p_container">
            <Switch>
              {couputeRoute(roles, false).map((route, i) => {
                if (i === 0) {
                  Object.assign(route, {
                    path: "/"
                  });
                }
                return (
                  <RouteWithSubRoutes
                    key={shortid.generate().substr(1, 2)}
                    {...route}
                  />
                );
              })}
              {<Route component={NoMatch} />}
            </Switch>
          </div>
        </div>
      </div>
    </Router>
  );
};

App.propTypes = {
  fetchUserCrops: PropTypes.func.isRequired
};
const mapState = state => ({});
const mapDispatch = dispatch => ({
  fetchUserCrops: () => dispatch({ type: "FETCH_USER_CROPS" })
});
const newApp = connect(
  mapState,
  mapDispatch
)(App);
export default newApp;
