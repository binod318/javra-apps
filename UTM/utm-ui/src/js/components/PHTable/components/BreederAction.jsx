import React from 'react';
import PropTypes from 'prop-types';
import { Cell } from 'fixed-data-table-2';

const BreederAction = ({
  ids,
  onRemove,
  onUpdate,
  rolesManagemasterdatautm,
  rolesRequest
}) => {
  if (!rolesRequest && rolesManagemasterdatautm) {
    return (
      <Cell className="bAction" align="center">
        <i
          role="button"
          tabIndex={0}
          title="Delete"
          className="icon icon-cancel"
          onKeyPress={() => {}}
          onClick={() => onRemove(ids)}
        />
      </Cell>
    );
  }
  return (
    <Cell className="bAction">
      <i
        role="button"
        tabIndex={0}
        title="Delete"
        className="icon icon-cancel"
        onKeyPress={() => {}}
        onClick={() => onRemove(ids)}
      />
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
  onUpdate: PropTypes.func.isRequired,
  onRemove: PropTypes.func.isRequired,
  ids: PropTypes.number.isRequired,
  rolesRequest: PropTypes.any.isRequired, // eslint-disable-line react/forbid-prop-types
  rolesManagemasterdatautm: PropTypes.any.isRequired // eslint-disable-line react/forbid-prop-types
};

export default BreederAction;
