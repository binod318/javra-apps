import React from "react";
import PropTypes from "prop-types";
import { Cell } from "fixed-data-table-2";

const LDOverviewAction = props => {
  const { onexport, ondelete, data } = props;
  const { testID, statusCode } = data;

  const showDelete = statusCode <= 150;
  const showExcel = statusCode >= 600;

  if (!showDelete && !showExcel) {
    return null;
  }

  return (
    <Cell align="center">
      {showDelete && (
        <i
          role="button"
          tabIndex={0}
          title="Delete"
          className="icon icon-trash"
          onKeyPress={() => {}}
          onClick={() => ondelete(testID, data)}
        />
      )}
      {showExcel && (
        <i
          role="button"
          tabIndex={0}
          title="Export"
          className="icon icon-file-excel"
          onKeyPress={() => {}}
          onClick={() => onexport(testID, data)}
        />
      )}
    </Cell>
  );
};

LDOverviewAction.propTypes = {
  ondelete: PropTypes.func.isRequired,
  data: PropTypes.object.isRequired, // eslint-disable-line react/forbid-prop-types
  onexport: PropTypes.func.isRequired // eslint-disable-line react/forbid-prop-types
};
export default LDOverviewAction;
