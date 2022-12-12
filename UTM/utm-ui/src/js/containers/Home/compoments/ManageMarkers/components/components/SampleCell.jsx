import React, { Component } from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { Cell } from 'fixed-data-table-2';
import autoBind from 'auto-bind';

class SampleComponent extends Component {
  constructor(props) {
    super(props);
    this.min = 1;
    this.max = 92 * 5;
    autoBind(this);
  }

  sampleChange(e) {
    const { rowIndex, sampleNumber } = this.props;
    const { value } = e.target;
    const { materialID } = sampleNumber[rowIndex];
    if (value * 1 && value * 1 > 0 && value >= this.min && value <= this.max) {
      this.props.sampleChange(materialID, value * 1);
    } else if (value === '' || value * 1 === 0) {
      this.props.sampleChange(materialID, value);
    }
  }

  blur = e => {
    const { rowIndex, sampleNumber } = this.props;
    const { value } = e.target;
    const { materialID } = sampleNumber[rowIndex];
    if (value === '' || value * 1 === 0) {
      this.props.sampleChange(materialID, 1);
    }
  };

  inputFocus = e => {
    e.preventDefault();
    const { rowIndex } = this.props;
    this.props.indexChange(rowIndex);
  };

  render() {
    const { rowIndex, sampleNumber } = this.props;
    const { nrOfSample } = sampleNumber[rowIndex];

    return (
      <Cell className="tableInputSampleNr">
        <input
          type="text"
          key={rowIndex}
          tabIndex={rowIndex + 1}
          value={nrOfSample || 0}
          onChange={this.sampleChange}
          min={1}
          max={this.max}
          onFocus={this.inputFocus}
          onBlur={this.blur}
          className="noscroll"
          readOnly={this.props.statusCode >= 200}
        />
      </Cell>
    );
  }
}

SampleComponent.defaultProps = {
  // data: [],
  sampleNumber: [],
  statusCode: 0
};
SampleComponent.propTypes = {
  rowIndex: PropTypes.number.isRequired,
  sampleNumber: PropTypes.array, // eslint-disable-line react/forbid-prop-types,
  sampleChange: PropTypes.func.isRequired,
  indexChange: PropTypes.func.isRequired,
  statusCode: PropTypes.number
  // data: PropTypes.array // eslint-disable-line react/forbid-prop-types
};
const mapStateToProps = state => ({
  statusCode: state.rootTestID.statusCode,
  sampleNumber: state.assignMarker.numberOfSamples.samples,
  sampleRefresh: state.assignMarker.numberOfSamples.refresh
});

const mapDispatchProps = dispatch => ({
  sampleChange: (materialID, nrOfSample) => {
    dispatch({
      type: 'SAMPLE_NUMBER_CHANGE',
      materialID,
      nrOfSample
    });
  }
});

export default connect(
  mapStateToProps,
  mapDispatchProps
)(SampleComponent);
