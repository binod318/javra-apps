import React from "react";
import { Cell } from "fixed-data-table-2";

class CheckCell extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      check: this.checkFunc(),
    };
  }
  handleChange = (e) => {
    const { rowIndex, data } = this.props;
  };

  checkFunc = () => {
    const { rowIndex, data } = this.props;
    if (data[rowIndex] === undefined) return false;

    const { RepeatIndicator } = data[rowIndex];

    if (RepeatIndicator !== undefined) return !RepeatIndicator;

    return true;
  };

  render() {
    const { arrayKey, rowIndex, data } = this.props;
    const n = `${arrayKey}-${rowIndex}`;

    if (data[rowIndex] === undefined || data[rowIndex].group) {
      return (
        <Cell style={{ textAlign: "center" }} className='tableCheck'>
          <div className='tableCheck'>
            <input
              id={n}
              type='checkbox'
              checked={this.state.check}
              onChange={this.handleChange}
              disabled={this.props.disableStatus}
            />
            <label htmlFor={n} />
          </div>
        </Cell>
      );
      return null;
    }

    return (
      <Cell style={{ textAlign: "center" }} className='tableCheck'>
        <div className='tableCheck'>
          <input
            id={n}
            type='checkbox'
            checked={this.state.check}
            onChange={this.handleChange}
            disabled={this.props.disableStatus}
          />
          <label htmlFor={n} />
        </div>
      </Cell>
    );
  }
}
export default CheckCell;
