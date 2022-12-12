import React from 'react';
import PropTypes from 'prop-types';
import { Cell } from 'fixed-data-table-2';

const ActionCell = props => {
  const { rowIndex, onRemove, onUpdate } = props;
  const traitDeterminationResultID = rowIndex;
  return (
    <Cell>
      <i
        role="button"
        tabIndex={0}
        className="icon icon-pencil"
        onKeyPress={() => {}}
        onClick={() => onUpdate(traitDeterminationResultID)}
      />
      <i
        role="button"
        tabIndex={0}
        className="icon icon-cancel"
        onKeyPress={() => {}}
        onClick={() => onRemove(traitDeterminationResultID)}
      />
    </Cell>
  );
};
ActionCell.defaultProps = {
  rowIndex: 0
};
ActionCell.propTypes = {
  rowIndex: PropTypes.number,
  onUpdate: PropTypes.func.isRequired,
  onRemove: PropTypes.func.isRequired // eslint-disable-line react/forbid-prop-types
};
export default ActionCell;
