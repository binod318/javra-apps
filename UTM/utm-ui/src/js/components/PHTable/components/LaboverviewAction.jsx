import React from 'react';
import PropTypes from 'prop-types';
import { Cell } from 'fixed-data-table-2';

const BreederAction = props => {
  const { ids, onUpdate } = props;

  return (
    <Cell className="cell-center">
      <i
        role="button"
        tabIndex={0}
        title="Edit"
        className="icon icon-pencil"
        onKeyPress={() => {}}
        onClick={() => onUpdate(ids)}
      />
    </Cell>
  );
};

BreederAction.propTypes = {
  ids: PropTypes.number.isRequired,
  onUpdate: PropTypes.func.isRequired
};
export default BreederAction;
