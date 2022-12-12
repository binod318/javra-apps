import React from "react";
import PropTypes from "prop-types";

import Manage2GB from "./components/Manage2GB";
import Manage3GB from "./components/Manage3GB";
import ManageS2S from "./components/ManageS2S";
import ManageCNT from "./components/ManageCNT";
import ManageRDT from "./components/ManageRDT";

function ManageMarkers(props) {
  if (!props.testTypeID) return null;

  const { testTypeID, importLevel } = props;

  switch (testTypeID) {
    case 4: // 3GB
    case 5: // 3GB
    case 2: // DNA
      return <Manage3GB {...props} />;
    case 6: // S2S Type
      return <ManageS2S {...props} testTypeID={testTypeID} />;
    case 7: // CNT
      return <ManageCNT {...props} testTypeID={testTypeID} />;
    case 8: // RDT
      return <ManageRDT {...props} testTypeID={testTypeID} />;
    default:
      return <Manage2GB {...props} sample={importLevel === "LIST"} />;
  }
}

ManageMarkers.defaultProps = {
  importLevel: "",
  testTypeID: ""
};
ManageMarkers.propTypes = {
  importLevel: PropTypes.string,
  testTypeID: PropTypes.number
};
export default ManageMarkers;
