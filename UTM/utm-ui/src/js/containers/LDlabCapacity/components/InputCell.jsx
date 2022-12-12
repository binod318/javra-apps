import React from "react";
import PropTypes from "prop-types";
import { Cell } from "fixed-data-table-2";

class InputCell extends React.Component {
  constructor(props) {
    super(props);
    // start -> code moved from componentDidMount // Eslint error
    let value = "";
    const { data, rowIndex, arrayKey } = props;
    if (data[rowIndex][arrayKey] !== null) {
      const testKey = arrayKey.charAt(0).toLowerCase() + arrayKey.slice(1);
      value = data[rowIndex][testKey];
    }
    // end

    this.state = {
      inputDisplay: !false,
      periodID: "",
      testKey: "",
      value,
      focus: false
    };
  }

  change = e => {
    const { rowIndex, change } = this.props;
    const {
      target: { name, value }
    } = e;
    const { periodID, testKey } = this.state;

    switch (name) {
      case "number":
        this.setState({ value });
        if (value > -1) {
          change(rowIndex, testKey, value, periodID);
        }
        break;
      case "text":
        change(rowIndex, testKey, value, periodID);
        break;
      default:
    }
  };

  click = () => {
    this.setState({ inputDisplay: true });
  };

  blur = () => {
    setTimeout(() => {
      this.setState({ focus: false });
    }, 500);
  };
  focus = e => { // eslint-disable-line
    const { rowIndex, arrayKey, data } = this.props;
    const { periodID } = data[rowIndex];

    const testKey = arrayKey.charAt(0).toLowerCase() + arrayKey.slice(1);
    this.setState({
      periodID,
      testKey,
      focus: true
    });
  };

  applyToAll = () => {
    const { value, testKey } = this.state;
    this.props.applyToAll(testKey, value);
  };

  render() {
    const { rowIndex, data, arrayKey, editable, dataType } = this.props;
    const { inputDisplay, focus } = this.state;

    const inputType = dataType === "Number" ? "number" : "text";

    if (arrayKey === "PeriodName") {
      const period = data[rowIndex];
      return <Cell>{period.periodName}</Cell>;
    }

    let display = "";
    if (data[rowIndex][arrayKey] !== null) {
      const testKey = arrayKey.charAt(0).toLowerCase() + arrayKey.slice(1);
      display = data[rowIndex][testKey] || "";
    }
    if (arrayKey === "Remark") {
      return (
        <Cell>
          <input
            type={inputType}
            name={inputType}
            value={display}
            onClick={this.click}
            onChange={this.change}
            readOnly={!inputDisplay}
            disabled={!editable}
            onFocus={this.focus}
          />
        </Cell>
      );
    }
    return (
      <Cell className="tableInputSampleNr" onBlur={this.blur}>
        <div style={{ display: "flex" }}>
          <input
            key="rowIndex"
            type={inputType}
            name={inputType}
            value={display}
            onChange={this.change}
            readOnly={!inputDisplay}
            disabled={!editable}
            onClick={this.click}
            onFocus={this.focus}
          />
          {editable && focus && (
            <button onClick={this.applyToAll} tabIndex="-1">
              To all
            </button>
          )}
        </div>
      </Cell>
    );
  }
}
InputCell.defaultProps = {
  data: [],
  arrayKey: "",
  rowIndex: 0
};
InputCell.propTypes = {
  applyToAll: PropTypes.func.isRequired,
  change: PropTypes.func.isRequired,
  rowIndex: PropTypes.number,
  data: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  arrayKey: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  editable: PropTypes.bool.isRequired,
  dataType: PropTypes.string.isRequired
};
export default InputCell;
