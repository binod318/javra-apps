import React, { Component } from "react";
import autoBind from "auto-bind";
import { Cell } from "fixed-data-table-2";
import PropTypes from "prop-types";
import { connect } from "react-redux";

class ScoreComponent extends Component {
  constructor(props) {
    super(props);
    this.state = {
      // statusCode: props.statusCode,
      name: "",
      valueNumber: "", // this.computevalue() // props.columnKey === 'NrOfSamples' ? 200 : 0
      focus: false,
      scoreMaps: props.scoreMaps
      // refresh: props.refresh
    };
    autoBind(this);
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.refresh !== this.props.refresh) {
      this.setState({
        scoreMaps: nextProps.scoreMaps
      });
    }
    if (nextProps.data.length > 0) {
      this.setState({
        valueNumber: this.getValue()
      });
    }
  }

  getValue = () => {
    const { traitID, rowIndex, data } = this.props;
    const { scoreMaps } = this.state;
    const { materialID } = data[rowIndex];

    const holder = scoreMaps[`${materialID}-${traitID.toLowerCase()}`];
    if (holder !== undefined) {
      const { newState } = holder;
      return newState;
    }
    return "";
  };

  handleChange = e => {
    const { target } = e;
    const { name, value } = target;
    this.setState({ valueNumber: value });

    this.props.scoreChange(name, value);
  };
  blur = () => {
    setTimeout(() => {
      this.setState({ focus: false });
    }, 500);
  };
  focus = e => {
    const { target } = e;
    const { name } = target;
    this.setState({
      name,
      focus: true
    });
  };
  applyToAll = () => {
    const { name, valueNumber } = this.state;
    const { scoreMaps } = this.props;
    const { changed, value } = scoreMaps[name];
    // if (!confirm('are you sure')) return;
    if (changed) {
      this.props.scoreApplyAll(name, valueNumber);
      return;
    }
    this.props.scoreApplyAll(name, value);
  };

  render() {
    const { traitID, rowIndex, data } = this.props;
    // columnKey,
    const { focus } = this.state;
    const { materialID } = data[rowIndex];

    const { scoreMaps } = this.state;

    const holder = scoreMaps[`${materialID}-${traitID.toLowerCase()}`];
    let val = "";
    if (holder !== undefined) {
      const { newState } = holder;
      val = newState;
    }

    return (
      <Cell className="tableInputSampleNr" onBlur={this.blur}>
        <div style={{ display: "flex" }}>
          <input
            tabIndex={rowIndex + 1}
            key={`${materialID}-${traitID.toLowerCase()}`}
            name={`${materialID}-${traitID.toLowerCase()}`}
            type="text"
            defaultValue={val}
            onChange={this.handleChange}
            className="noscroll"
            onFocus={this.focus}
          />
          {focus && (
            <button tabIndex={-1} onClick={this.applyToAll}>
              To all
            </button>
          )}
        </div>
      </Cell>
    );
  }
}

ScoreComponent.defaultProps = {
  traitID: null
  // columnKey: null
};

ScoreComponent.propTypes = {
  refresh: PropTypes.bool.isRequired,
  scoreChange: PropTypes.func.isRequired,
  scoreApplyAll: PropTypes.func.isRequired,
  // statusCode: PropTypes.number.isRequired,
  rowIndex: PropTypes.number.isRequired,
  // columnKey: PropTypes.string,
  traitID: PropTypes.string,
  data: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  scoreMaps: PropTypes.oneOfType([PropTypes.array, PropTypes.object]).isRequired // eslint-disable-line react/forbid-prop-types
};

const mapStateToProps = state => ({
  statusCode: state.rootTestID.statusCode
});
const mapDispatchProps = dispatch => ({
  scoreChange: (name, value) => {
    dispatch({
      type: "UPDATE_SOCREMAP",
      name,
      value
    });
  },
  scoreApplyAll: (name, value) =>
    dispatch({
      type: "UPDATE_SCOREMAP_ALL",
      name,
      value
    })
});

const ScoreCell = connect(
  mapStateToProps,
  mapDispatchProps
)(ScoreComponent);
export default ScoreCell;
