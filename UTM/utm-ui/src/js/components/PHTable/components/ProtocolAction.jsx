import React from 'react';
import PropTypes from 'prop-types';
import { Cell } from 'fixed-data-table-2';

const ProtocolAction = props => {
  const { onUpdate, ids } = props;
  return (
    <Cell>
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
ProtocolAction.defaultProps = {
  ids: 0
};
ProtocolAction.propTypes = {
  ids: PropTypes.number,
  onUpdate: PropTypes.func.isRequired
};
export default ProtocolAction;
