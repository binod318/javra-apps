import React from "react";
import PropTypes from "prop-types";
import { Cell } from "fixed-data-table-2";

const RDToverviewAction = props => {
  const { onexport, ondelete, data } = props;
  const { testID, statusCode } = data;

  const statusGreaterAndEqual700 = statusCode >= 700;
  const statusGreaterAndEqual100 = statusCode <= 100;
  const statusIsEqualTo550 = statusCode === 550;

  const showDelete = statusGreaterAndEqual100;
  const showExcel = statusGreaterAndEqual700 || statusIsEqualTo550;

  if (!statusIsEqualTo550 && statusCode < 700 && statusCode > 100) {
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

RDToverviewAction.propTypes = {
  ondelete: PropTypes.func.isRequired,
  data: PropTypes.object.isRequired, // eslint-disable-line react/forbid-prop-types
  onexport: PropTypes.func.isRequired // eslint-disable-line react/forbid-prop-types
};
export default RDToverviewAction;
