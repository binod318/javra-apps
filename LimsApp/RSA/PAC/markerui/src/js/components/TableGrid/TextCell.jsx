import React from "react";
import PropTypes from "prop-types";
import { Cell } from "fixed-data-table-2";

class TextCell extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      inputDisplay: !false,
      PeriodID: "",
      name: "",
      value: props.data[props.rowIndex][props.name] || "",
      focus: false,
    };
  }

  handleChange = (e) => {
    console.log(e.target.value);
  };
  focus = () => {
    const { rowIndex, name, data } = this.props;
    const { PeriodID } = data[rowIndex];
    // const testKey = arrayKey.charAt(0) + arrayKey.slice(1);
    this.setState({ PeriodID, name, focus: true });
  };

  render() {
    const { data, rowIndex, name } = this.props;
    return (
      <Cell>
        <input
          tabIndex={rowIndex}
          key={`${name}-${rowIndex}`}
          type='text'
          value={this.state.value}
          onChange={this.handleChange}
          onFocus={this.focus}
        />
      </Cell>
    );
  }
}
export default TextCell;
