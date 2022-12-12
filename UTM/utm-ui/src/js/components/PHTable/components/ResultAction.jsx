import React from 'react';
import PropTypes from 'prop-types';
import { Cell } from 'fixed-data-table-2';

const ResultAction = props => {
  const { data, onRemove, onUpdate, ids, role } = props;
  const { relationID, id, cropCode } = data;

  // #26987 if user has managemasterdatautm role then user can add/edit data otherwise not
  if(role.includes('managemasterdatautm'))
    return (
      <Cell>
        <i
          role="button"
          tabIndex={0}
          className="icon icon-pencil"
          onKeyPress={() => {}}
          onClick={() => onUpdate(ids)}
        />
        {relationID !== 0 && (
          <i
            role="button"
            tabIndex={0}
            className="icon icon-cancel"
            onKeyPress={() => {}}
            onClick={() => onRemove(id, cropCode)}
          />
        )}
      </Cell>
    );
  else
    return (
      <Cell/>
    );
};

ResultAction.defaultProps = {
  data: {},
  ids: 0,
  role: []
};
ResultAction.propTypes = {
  data: PropTypes.object, // eslint-disable-line react/forbid-prop-types
  ids: PropTypes.number,
  onUpdate: PropTypes.func.isRequired,
  onRemove: PropTypes.func.isRequired // eslint-disable-line react/forbid-prop-types
};
export default ResultAction;
