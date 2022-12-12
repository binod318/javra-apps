import React, { useState, useEffect } from "react";
import { withRouter } from "react-router-dom";
import { connect } from "react-redux";
import PropTypes from "prop-types";
import "./aside.scss";
import CustomLink from "./CustomeLink";
import { couputeRoute } from "../../routes";
import { hiddenTesttypes } from "../../helpers/helper";

const Aside = ({ role, testTypeID, onclick, setMenu, sideStatus, dirty, isColumnMarkerDirty }) => {
  const [selectedMenuGroup, setSelectedMenuGroup] = useState("utmGeneral");
  useEffect(() => {
    const menuGroup =
      window.localStorage.getItem("selectedMenuGroup") || "utmGeneral";
    setSelectedMenuGroup(menuGroup);
  }, []);

  const updateSelectedMenuGroup = menuGroup => {

    if((dirty === true || isColumnMarkerDirty === true) && !confirm("There are unsaved changes!")) return;

    setSelectedMenuGroup(menuGroup);
    window.localStorage.setItem("selectedMenuGroup", menuGroup);
    setMenu(menuGroup); //Refresh screen based on selected menu
  };

  const getMenuGroupLinks = menuGroup =>
    couputeRoute(role, testTypeID, menuGroup).map(route => (
      <CustomLink
        key={route.id}
        to={route.to}
        label={route.name}
        id={route.id}
        icon={route.icon}
      />
    ));

  //Testtype Value that comes in hiddenTesttypes() should be hidden
  const hideRDT = hiddenTesttypes().indexOf('rdt') > -1;
  const hideLeafdisk = hiddenTesttypes().indexOf('ldisk') > -1;
  const hideSeedHealth = hiddenTesttypes().indexOf('seedhealth') > -1;

  return (
    <aside>
      <ul>
        <li style={{ borderBottom: "1px #d0cbcb solid", marginBottom: "10px" }}>
          <button onClick={onclick} id={!sideStatus ? "h" : "h_c"}>
            <i className="icon icon-menu" />
            <i className="icon icon-down" />
          </button>
        </li>
      </ul>
      <div
        className={`menuGroup ${
          selectedMenuGroup === "utmGeneral" ? "selected" : ""
        }`}
      >
        <label
          className="menuGroup--link"
          onClick={() => updateSelectedMenuGroup("utmGeneral")}
        >
          2GB, 3GB, S2S, C&T{" "}
        </label>
        <ul className="menuGroup--link-list">
          {getMenuGroupLinks("utmGeneral")}
        </ul>
      </div>
      {!hideRDT && (
        <div
          className={`menuGroup ${selectedMenuGroup === "rdt" ? "selected" : ""}`}
        >
          <label
            className="menuGroup--link"
            onClick={() => updateSelectedMenuGroup("rdt")}
          >
            RDT
          </label>
          <ul className="menuGroup--link-list">{getMenuGroupLinks("rdt")}</ul>
        </div>
      )}
      {!hideLeafdisk && (
        <div
          className={`menuGroup ${
            selectedMenuGroup === "leafDisk" ? "selected" : ""
          }`}
        >
           <label
            className="menuGroup--link"
            onClick={() => updateSelectedMenuGroup("leafDisk")}
          >
          Leaf Disk{" "}
        </label>
        <ul className="menuGroup--link-list">
          {getMenuGroupLinks("leafDisk")}
        </ul>
      </div>
      )}
      {!hideSeedHealth && (
        <div
          className={`menuGroup ${
            selectedMenuGroup === "seedHealth" ? "selected" : ""
          }`}
        >
          <label
            className="menuGroup--link"
            onClick={() => updateSelectedMenuGroup("seedHealth")}
          >
            Seed Health{" "}
          </label>
          <ul className="menuGroup--link-list">
            {getMenuGroupLinks("seedHealth")}
          </ul>
        </div>
      )}
    </aside>
  );
};

const mapStateToProps = state => ({
  testTypeID: state.rootTestID.testTypeID,
  role: state.user.role,
  dirty: state.assignMarker.materials.dirty,
  isColumnMarkerDirty: state.assignMarker.determinations.isColumnMarkerDirty
});

Aside.defaultProps = {
  role: [],
  testTypeID: 1,
  dirty: false,
  isColumnMarkerDirty: false,
  onclick: () => {}
};
Aside.propTypes = {
  sideStatus: PropTypes.bool.isRequired,
  onclick: PropTypes.func,
  testTypeID: PropTypes.number,
  role: PropTypes.array // eslint-disable-line
};
export default withRouter(
  connect(
    mapStateToProps,
    null
  )(Aside)
);
