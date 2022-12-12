import React from 'react';
import PropTypes from 'prop-types';
import { Cell } from 'fixed-data-table-2';

const CTAction = props => {
  const { onUpdate, ids } = props;
  return (
    <Cell style={{ textAlign: 'center' }}>
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
CTAction.defaultProps = {
  ids: 0
};
CTAction.propTypes = {
  ids: PropTypes.number,
  onUpdate: PropTypes.func.isRequired
};
export default CTAction;
