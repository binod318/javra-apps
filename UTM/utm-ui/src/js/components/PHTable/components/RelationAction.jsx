import React from 'react';
import PropTypes from 'prop-types';
import { Cell } from 'fixed-data-table-2';

const RelationAction = props => {
  const { data, onRemove, onUpdate, role } = props;
  const { relationID, traitID } = data;

  // #26987 if user has managemasterdatautm role then user can add/edit data otherwise not
  if(role.includes('managemasterdatautm'))
    return (
      <Cell>
        <i
          role="button"
          tabIndex={0}
          className="icon icon-pencil"
          onKeyPress={() => {}}
          onClick={() => onUpdate(traitID)}
        />
        {relationID !== 0 && (
          <i
            role="button"
            tabIndex={0}
            className="icon icon-cancel"
            onKeyPress={() => {}}
            onClick={() => onRemove(relationID)}
          />
        )}
      </Cell>
    );
  else
    return (
      <Cell/>
    );
};

RelationAction.defaultProps = {
  data: {},
  role: []
};

RelationAction.propTypes = {
  data: PropTypes.object, // eslint-disable-line react/forbid-prop-types
  onRemove: PropTypes.func.isRequired,
  onUpdate: PropTypes.func.isRequired
};
export default RelationAction;
