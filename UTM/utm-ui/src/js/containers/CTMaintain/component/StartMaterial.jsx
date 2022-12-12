import React, { Component } from "react";
import PropTypes from "prop-types";
import PHTable from "../../../components/PHTable";
import { getDim } from "../../../helpers/helper";

class StartMaterial extends Component {
  constructor(props) {
    super(props);
    this.state = {
      tblWidth: 0,
      tblHeight: 0
    };
  }
  componentDidMount() {
    window.addEventListener("resize", this.updateDimensions);
    this.updateDimensions();
  }
  shouldComponentUpdate(nextProps) {
    if (this.props.mode !== nextProps.mode) {
      return false;
    }
    return true;
  }
  componentWillUnmount() {
    window.removeEventListener("resize", this.updateDimensions);
  }

  updateDimensions = () => {
    const dim = getDim();
    this.setState({
      tblWidth: dim.width,
      tblHeight: dim.height
    });
  };

  edit = id => {
    this.props.dataChange(id);
  };

  render() {
    const { tblHeight, tblWidth } = this.state;
    const calcTblHeight = tblHeight - 125 - 60;
    const columns = ["startMaterialName", "statusName", "Action"];
    const columnsMapping = {
      startMaterialName: {
        name: "Start Material Name",
        filter: false,
        fixed: false
      },
      statusName: { name: "Status", filter: false, fixed: false },
      Action: { name: "Action", filter: false, fixed: false }
    };
    const columnsWidth = {
      startMaterialName: 280,
      statusName: 100,
      recipients: 300,
      Action: 100
    };
    return (
      <div>
        <PHTable
          sideMenu={this.props.sideMenu}
          filter={[]}
          tblWidth={tblWidth}
          tblHeight={calcTblHeight}
          columns={columns}
          data={this.props.data}
          pagenumber={1}
          pagesize={this.props.total}
          total={this.props.total}
          pageChange={() => {}}
          filterFetch={() => {}}
          filterClear={() => {}}
          columnsMapping={columnsMapping}
          columnsWidth={columnsWidth}
          filterAdd={() => {}}
          actions={{
            name: "ctmaintain",
            edit: this.edit
          }}
        />
      </div>
    );
  }
}

StartMaterial.defaultProps = {
  data: [],
  total: 0
};
StartMaterial.propTypes = {
  mode: PropTypes.any, // eslint-disable-line
  dataChange: PropTypes.func.isRequired,
  sideMenu: PropTypes.bool.isRequired,
  data: PropTypes.array, // eslint-disable-line
  total: PropTypes.number
};
export default StartMaterial;
