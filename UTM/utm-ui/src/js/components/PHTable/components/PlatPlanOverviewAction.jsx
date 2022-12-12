import React from "react";
import PropTypes from "prop-types";
import { Cell } from "fixed-data-table-2";

const PlatePlanOverviewAction = props => {
  const { onexport, ondelete, data, accessRole, isBTR, sampleList } = props;
  const { testID, statusCode, testTypeID } = data;

  const showTrashBtn = statusCode === 500 && accessRole;
  const showCompletedBtn = isBTR ? statusCode >= 500 : statusCode === 700;
  const condTestType = testTypeID === 1;
  const showCompletedBtn1 = testTypeID ===2 ? statusCode >= 400 : statusCode === 700; 
  const showSampleListBtn = statusCode >= 400;

  return (
    <Cell align="center">
      {showTrashBtn && (
        <i
          role="button"
          tabIndex={0}
          title="Delete"
          className="icon icon-trash"
          onKeyPress={() => {}}
          onClick={() => ondelete(testID, data)}
        />
      )}
      {(showCompletedBtn1 || (condTestType && showCompletedBtn)) &&  (
        <i
          role="button"
          tabIndex={0}
          title="Export"
          className="icon icon-file-excel"
          onKeyPress={() => {}}
          onClick={() => onexport(testID, data)}
        />
      )}
      {showSampleListBtn && (
        <i
          role="button"
          tabIndex={0}
          title="Sample list"
          className="icon icon-print"
          onKeyPress={() => {}}
          onClick={() => sampleList(testID)}
        />
      )}
    </Cell>
  );
};

PlatePlanOverviewAction.propTypes = {
  ondelete: PropTypes.func.isRequired,
  accessRole: PropTypes.any, // eslint-disable-line
  data: PropTypes.object.isRequired, // eslint-disable-line react/forbid-prop-types
  onexport: PropTypes.func.isRequired, // eslint-disable-line react/forbid-prop-types
  isBTR: PropTypes.bool.isRequired
};
export default PlatePlanOverviewAction;
