import React from "react";
import { connect } from "react-redux";
import PropTypes from "prop-types";

import { sidemenuClose } from "../../action/index";
import RowDraw from "./components/RowDraw";
import RowHead from "./components/RowHead";
import "./ld-punchlist.scss";

class LDPunchList extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      data: props.punchList
    };
    this.props.pageTitle();
  }

  componentDidMount() {
    if (this.props.testID) {
      this.props.fetch_punchList(this.props.testID);
    } else {
      this.props.history.push("/");
    }
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.punchList !== this.props.punchList) {
      this.setState({ data: nextProps.punchList });
    }
  }

  render() {
    const data = this.state.data || {};
    const { columns, rows, cellsPerRow } = data;
    const chunckedRows = [];
    if (rows) {
      for (let i = 0, j = rows.length; i < j; i += 5) {
        const partialRows = rows.slice(i, i + 5);
        chunckedRows.push({
          cols: columns,
          rows: partialRows
        });
      }
    }

    return (
      <div className="container punchlist">
        <div className="trow">
          <div className="tcell">
            <div>
              {chunckedRows.map((chunkRow, chunkIndex) => {
                return (
                  <div  key={chunkIndex} className="plateWrap"> {/*eslint-disable-line*/}
                    <div>
                      <div>
                        <RowHead
                          cols={chunkRow.cols}
                          cellsPerRow={cellsPerRow}
                        />
                        <div>
                          {chunkRow.rows.map((chunckRow, rowIndex) => (
                            <div className="rowWrapper" key={rowIndex}>  {/*eslint-disable-line*/}
                              <div>{chunckRow.rowHeader}</div>
                              <div className="rowsTest">
                                <RowDraw
                                  row={chunckRow}
                                  cellsPerRow={cellsPerRow}
                                />
                              </div>
                            </div>
                          ))}
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      </div>
    );
  }
}

const mapState = state =>
  console.log(state.assignMarker.ldPunchList) || {
    testID: state.rootTestID.testID,
    punchList: state.assignMarker.ldPunchList
  };
const mapDispatch = dispatch => ({
  pageTitle: () => {
    dispatch({
      type: "SET_PAGETITLE",
      title: "Leaf Disk Punch List"
    });
  },
  sidemenu: () => dispatch(sidemenuClose()),
  fetch_punchList: testID => {
    dispatch({
      type: "LD_FETCH_PUNCHLIST",
      testID
    });
  }
});
LDPunchList.defaultProps = {
  testID: 0
};
LDPunchList.propTypes = {
  fetch_punchList: PropTypes.func.isRequired,
  pageTitle: PropTypes.func.isRequired,
  testID: PropTypes.number,
  history: PropTypes.array.isRequired, // eslint-disable-line
  punchList: PropTypes.object.isRequired // eslint-disable-line react/forbid-prop-types
};

export default connect(
  mapState,
  mapDispatch
)(LDPunchList);
