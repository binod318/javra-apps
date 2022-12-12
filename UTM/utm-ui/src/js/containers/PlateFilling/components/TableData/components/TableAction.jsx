import React from "react";
import PropTypes from "prop-types";
import "./tableaction.scss";

const TableAction = ({
  importLevel,
  // btnStat,
  selected,
  selectArray,
  // selectArrayLength,
  up,
  down,
  move,
  del,
  handleCreateReplicaBtnClick,
  undo,
  data,
  undoFixed
  // replicaDelete,
  // isReplica
}) => {
  const { wellTypeID, fixed } = data[selected];

  // not array and fixed
  const notArrayAndFixed = !selectArray && fixed;
  // not array and not fixed
  const notArrayAndNotFixed = !selectArray && !fixed;

  const wellTypeNotThree = wellTypeID !== 3;

  const moveUp =
    !importLevel && notArrayAndNotFixed ? (
      <button onClick={up} title="Move up">
        <i className="icon icon-up" />
      </button>
    ) : null;
  const moveDown =
    !importLevel && notArrayAndNotFixed ? (
      <button onClick={down} title="Move down">
        <i className="icon icon-down" />
      </button>
    ) : null;
  const jumpMove =
    !importLevel && (!notArrayAndFixed || wellTypeNotThree) ? (
      <button onClick={move} title="Jump">
        <i className="icon icon-arrow-combo" />
      </button>
    ) : null;
  const markDead =
    !notArrayAndFixed || wellTypeNotThree ? (
      <button onClick={del} title="Mark Dead" className="del">
        <i className="icon icon-trash" />
      </button>
    ) : null;
  const undoDead =
    !importLevel && (!notArrayAndFixed || wellTypeNotThree) ? (
      <button onClick={undo} title="Undo Dead">
        <i className="icon icon-ccw" />
      </button>
    ) : null;
  const undoFix =
    !importLevel && notArrayAndFixed ? (
      <button onClick={undoFixed} title="Unfix" className="">
        <i className="icon icon-doc-remove" />
      </button>
    ) : null;
  const createReplicaBtn =
    !importLevel && (!notArrayAndFixed || wellTypeNotThree) ? (
      <button onClick={handleCreateReplicaBtnClick} title="Create Replica">
        <i className="icon icon-docs" />
      </button>
    ) : null;

  return (
    <div className="directionBox">
      {moveUp}
      {moveDown}
      {jumpMove}
      {undoFix}
      {markDead}
      {undoDead}
      {createReplicaBtn}
    </div>
  );
};
TableAction.defaultProps = {
  selected: null,
  data: []
};
TableAction.propTypes = {
  // selectArrayLength: PropTypes.number.isRequired,
  // btnStat: PropTypes.bool.isRequired,
  undo: PropTypes.func.isRequired,
  del: PropTypes.func.isRequired,
  down: PropTypes.func.isRequired,
  handleCreateReplicaBtnClick: PropTypes.func.isRequired,
  move: PropTypes.func.isRequired,
  selectArray: PropTypes.bool.isRequired,
  selected: PropTypes.number,
  up: PropTypes.func.isRequired,
  undoFixed: PropTypes.func.isRequired,
  data: PropTypes.array, // eslint-disable-line
  importLevel: PropTypes.bool.isRequired
};
export default TableAction;
