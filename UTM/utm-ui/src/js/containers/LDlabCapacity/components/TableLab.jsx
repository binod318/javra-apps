import React from "react";
import PropTypes from "prop-types";
import { connect } from "react-redux";

import { Table, Column } from "fixed-data-table-2";
import "fixed-data-table-2/dist/fixed-data-table.css";
import "../../../../../node_modules/fixed-data-table-2/dist/fixed-data-table.min";

import InputCell from "./InputCell";
import HeaderCell from "./HeaderCell";

class TableLab extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      columns: props.columns,
      data: props.data,
      tblWidth: props.tblWidth,
      tblHeight: props.tblHeight
    };
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.columns) {
      this.setState({ columns: nextProps.columns });
    }
    if (nextProps.data) {
      this.setState({
        data: nextProps.data
      });
    }
    if (nextProps.tblWidth !== this.props.tblWidth) {
      this.setState({ tblWidth: nextProps.tblWidth });
    }
    if (nextProps.tblHeight !== this.props.tblHeight) {
      this.setState({ tblHeight: nextProps.tblHeight });
    }
  }

  render() {
    const { isChange, changeValue } = this.props;
    const { columns, data } = this.state;
    let { tblWidth, tblHeight } = this.state;

    tblWidth -= 30; // 80
    if (this.props.sideMenu) {
      tblWidth -= 200;
    } else {
      tblWidth -= 60;
    }
    tblHeight -= 120;

    columns.sort((a, b) => a.order - b.order);

    return (
      <Table
        rowHeight={42}
        headerHeight={40}
        rowsCount={data.length}
        width={tblWidth}
        height={tblHeight}
        {...this.props}
      >
        {columns
          .map(d => {
            const { columnID, label, isVisible, editable, dataType } = d;
            if (!isVisible) {
              return null;
            }
            let cellWidth = 150;
            let fixed = false;
            let grow = 0;
            if (columnID === "PeriodName") {
              fixed = true;
              cellWidth = 220;
            }
            if (columnID === "Remark") {
              cellWidth = 400;
              grow = 1;
            }
            return (
              <Column
                key={columnID}
                fixed={fixed}
                flexGrow={grow}
                header={<HeaderCell keyValue={columnID} view={label} />}
                columnKdy={columnID}
                width={cellWidth}
                cell={
                  <InputCell
                    arrayKey={columnID}
                    data={data}
                    change={changeValue}
                    isChanged={isChange}
                    applyToAll={this.props.applyToAll}
                    editable={editable}
                    dataType={dataType}
                  />
                }
              />
            );
          })
          .filter(Boolean)}
      </Table>
    );
  }
}

const mapState = state => ({
  sideMenu: state.sidemenuReducer,
  data: state.ldLabCapacity.data,
  columns: state.ldLabCapacity.column
});
const mapDispatch = dispatch => ({
  labDataChange: (index, key, value) => {
    dispatch({
      type: "RDT_LAB_DATA_CHANGE",
      index,
      key,
      value
    });
  }
});

TableLab.defaultProps = {
  data: [],
  columns: []
};

TableLab.propTypes = {
  sideMenu: PropTypes.bool.isRequired,
  data: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  columns: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  isChange: PropTypes.bool.isRequired,
  changeValue: PropTypes.func.isRequired,
  tblHeight: PropTypes.number.isRequired,
  tblWidth: PropTypes.number.isRequired,
  applyToAll: PropTypes.func.isRequired
};
export default connect(
  mapState,
  mapDispatch
)(TableLab);
