import React, { Component } from "react";
import autoBind from "auto-bind";
import PropTypes from "prop-types";

class LDActionCell extends Component {
  constructor(props) {
    super(props);
    autoBind(this);
  }

  deleteSample = rowIndex => e => {
    e.preventDefault();
    this.props.deleteSample(rowIndex);
  };

  render() {
    const { rowIndex, data } = this.props;
    return (
      <div>
        {data[rowIndex].delete === 1 && (
          <button
            onClick={this.deleteSample(rowIndex)}
            className="action-delete"
            title="Delete"
          >
            <i role="button" title="Delete" className="icon icon-cancel" />
          </button>
        )}
      </div>
    );
  }
}

LDActionCell.defaultProps = {
  rowIndex: 0
};

LDActionCell.propTypes = {
  rowIndex: PropTypes.number,
  deleteSample: PropTypes.func.isRequired,
  data: PropTypes.array.isRequired // eslint-disable-line react/forbid-prop-types
};

export default LDActionCell;
