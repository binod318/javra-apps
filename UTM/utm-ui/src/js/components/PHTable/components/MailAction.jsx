import React from 'react';
import PropTypes from 'prop-types';
import { Cell } from 'fixed-data-table-2';

const MailAction = props => {
  const { onAdd, onRemove, onUpdate, ids, data } = props;
  const { configID } = data;
  return (
    <Cell>
      <i
        role="button"
        tabIndex={0}
        title="Copy"
        className="icon icon-plus-squared"
        onKeyPress={() => {}}
        onClick={() => onAdd(configID)}
      />
      <i
        role="button"
        tabIndex={0}
        title="Edit"
        className="icon icon-pencil"
        onKeyPress={() => {}}
        onClick={() => onUpdate(configID)}
      />
      <i
        role="button"
        tabIndex={0}
        title="Delete"
        className="icon icon-cancel"
        onKeyPress={() => {}}
        onClick={() => onRemove(configID)}
      />
    </Cell>
  );
};
MailAction.defaultProps = {
  ids: 0
};
MailAction.propTypes = {
  ids: PropTypes.number,
  onAdd: PropTypes.func.isRequired,
  onUpdate: PropTypes.func.isRequired,
  onRemove: PropTypes.func.isRequired // eslint-disable-line react/forbid-prop-types
};
export default MailAction;
