import React from 'react';
import { Cell } from 'fixed-data-table-2';

// const Chk = ({ select, data, rowIndex, selected }) => {
class CheckData extends React.Component {
  handleChange = () => {
    const { data, rowIndex } = this.props;
    this.props.select(data[rowIndex]['varietyID'])
  };

  render () {
    const { data, rowIndex, selected } = this.props;
    const varietyID = data[rowIndex]['varietyID'];

    return (
      <div className="cellCheckBox">
        <Cell>
          <input
            type="checkbox"
            checked={selected.includes(varietyID)}
            onChange={this.handleChange}
          />
        </Cell>
      </div>
    );
  }
}
export default CheckData;
