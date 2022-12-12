import React from 'react';
import { Cell } from 'fixed-data-table-2';
import PropTypes from 'prop-types';

// aCheck,
const Action = ({ data, rowIndex, dataAdd, dataEdit, dataDelete, check, checkList }) => {
  const { traitScreeningID, traitID, traitScrResultID } = data[rowIndex];

  // for trait screening id
  let deletID = traitScreeningID;
  // condition for trait result id
  if (traitScrResultID !== undefined) {
    deletID = traitScrResultID;
  }

  if (check) {
    return (
      <Cell className="action center">
        <input
          id={`box_${rowIndex}-${traitID}`}
          name={`box_${rowIndex}-${traitID}`}
          type="checkbox"
          checked={checkList.includes(traitID)}
          // onChange={() => aCheck(traitID)}
        />
      </Cell>
    );
  }
  return (
    <Cell className="act ion">
      <i
        role="button"
        tabIndex={0}
        className="icon icon-plus-circle"
        onKeyPress={() => {}}
        onClick={() => dataAdd(rowIndex)}
      />
      &nbsp;&nbsp;&nbsp;
      <i
        role="button"
        tabIndex={0}
        className="icon icon-pencil"
        onKeyPress={() => {}}
        onClick={() => dataEdit(rowIndex)}
      />
      &nbsp;&nbsp;&nbsp;
      <i
        role="button"
        tabIndex={0}
        className="icon icon-cancel"
        onKeyPress={() => {}}
        onClick={() => dataDelete(rowIndex)}
      />
    </Cell>
  );
};

Action.defaultProps = {
  checkList: [],
  rowIndex: 0
};
Action.propTypes = {
  check: PropTypes.bool.isRequired,
  data: PropTypes.array.isRequired,  // eslint-disable-line
  rowIndex: PropTypes.number,
  dataEdit: PropTypes.func.isRequired,
  dataDelete: PropTypes.func.isRequired,
  // aCheck: PropTypes.func.isRequired,
  checkList: PropTypes.array  // eslint-disable-line
};
export default Action;
