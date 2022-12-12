import React, { Fragment } from "react";
import { Input, Button } from "antd";
import { getDim } from "../../helpers/helper";
import ActionBar from "../../components/ActionBar/ActionBar";
import Wrapper from "../../components/Wrapper/wrapper";
import AutoSuggestion from "../../components/AutoSuggestion";
import TblA from "../../components/TblA";
import {
  CheckCircleFilled,
  CloseCircleFilled,
  EditFilled,
  FilterFilled
} from "@ant-design/icons";
import { withAITracking } from '@microsoft/applicationinsights-react-js';
import { reactPlugin, appInsights } from '../../config/app-insights-service';

class MarkerPerVarietyComponent extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      data: props.data,
      columns: props.columns,
      tblWidth: 900,
      tblHeight: 600,
      formVisible: false,

      page: props.page,
      size: 50,
      pagination: {
        current: props.page,
      },
      filter: props.filter || {},
      total: props.total,
      sortBy: "",
      sortOrder: "",
      searchText: "",
      searchedColumn: "",

      MarkerPerVarID: 0,
      MarkerID: null,
      VarietyNr: null,
      CropCode: "",
      action: "i",
      Remarks: "",
      ExpectedResult: "",
      MarkerIDValue: "",
      VarietyNumber: "",

      crops: props.crops,
      routineMarkersOnly: true
    };
  }

  componentDidMount() {
    appInsights.trackPageView({ name: 'TraitMarkerPerVariety' });
    const { page, size, filter } = this.state;
    if (this.props.data.length === 0)
      this.props.fetchMarkerPerVariety(page, size, "", "", filter);

    this.props.pageSizeChange(size);
    this.updateDimensions();
    window.addEventListener("resize", this.updateDimensions);
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.data.length !== this.props.data.length) {
      this.setState({ formVisible: false, data: nextProps.data });
    }
    if (nextProps.data.length) {
      this.setState({ data: nextProps.data });
    }
    if (this.props.columns.length !== nextProps.columns.length) {
      this.setState({ columns: nextProps.columns });
      this.updateDimensions();
    }
    if (nextProps.filter) {
      this.setState({ filter: nextProps.filter });
    }
    if (nextProps.total !== this.props.total) {
      this.setState({ total: nextProps.total });
    }
    if (nextProps.page !== this.props.page) {
      this.setState({ page: nextProps.page });
    }
    if(nextProps.crops !== this.props.crops) {
      this.setState({ crops: nextProps.crops });
    }
  }

  componentWillUnmount() {
    window.removeEventListener("resize", this.updateDimensions);
  }

  updateDimensions = () => {
    const { width: tblWidth, height: tblHeight } = getDim();
    this.setState({ tblWidth, tblHeight });
  };

  formVisibleFunc = (flag) => {
    this.setState((state) => ({
      ...state,
      formVisible: flag,
      MarkerID: null,
      VarietyNr: null,
      CropCode: "",
      MarkerPerVarID: 0,
      action: "i",
      Remarks: "",
      ExpectedResult: "",
      MarkerIDValue: "",
      VarietyNumber: "",
    }));
  };

  handleChange = (event) => {
    const {
      target: { name, value },
    } = event;
    this.setState({
      [name]: value,
    });
  };

  handleCheckboxChange = () => {
    this.setState({
      routineMarkersOnly: !this.state.routineMarkersOnly,
      MarkerID: null
    });
  };

  changeFunc = (name, id) => this.setState({ [name]: id });

  getMarkers = (value) => {
    const { CropCode, routineMarkersOnly } = this.state;

    const showPacMarkers = !routineMarkersOnly;

    if(CropCode != '')
      this.props.getMarkerFunc(value, CropCode, showPacMarkers)
  }

  getVarieties = (value) => {
    const { CropCode } = this.state;

    if(CropCode != '')
      this.props.getVarietiesFunc(value, CropCode)
  }

  filterCrops = (value) => {
    var data = [];

    if(value === '')
      data = this.props.crops
    else
      data = this.props.crops.filter(o => o.label.toLowerCase().search(value.toLowerCase()) > -1);

    this.setState({
      crops: data
    })
  }

  submit = () => {
    if (!this.props.role) return null;
    const {
      MarkerPerVarID,
      MarkerID,
      VarietyNr,
      Remarks,
      ExpectedResult,
      action,
      MarkerIDValue,
      VarietyNumber,
    } = this.state;
    if (action === "u") {
      this.formVisibleFunc(false);
      this.props.postMarkerPerVarietyFunc(
        MarkerPerVarID,
        MarkerIDValue,
        VarietyNumber,
        Remarks,
        ExpectedResult,
        action
      );
      return null;
    }
    this.props.postMarkerPerVarietyFunc(
      MarkerPerVarID,
      MarkerID,
      VarietyNr,
      Remarks,
      ExpectedResult,
      action
    );
  };

  deleteFunc = (MarkerPerVarID, act) => {
    if (!this.props.role) return null;
    this.props.postMarkerPerVarietyFunc(MarkerPerVarID, 0, 0, 0, 0, act);
  };

  editFunc = (MarkerPerVarID) => {
    const selectedobj = this.state.data.find(
      (x) => x.MarkerPerVarID === MarkerPerVarID
    );
    this.setState({
      MarkerPerVarID: selectedobj.MarkerPerVarID,
      Remarks: selectedobj.Remarks === null ? "" : selectedobj.Remarks,
      ExpectedResult: selectedobj["ExpectedResult"] || "",
      MarkerID: selectedobj["MarkerID"] || "",
      VarietyNr: selectedobj["VarietyNr"] || "",
      CropCode: selectedobj["CropCode"] || "",
      action: "u",
      MarkerIDValue: selectedobj.MarkerID,
      VarietyNumber: selectedobj["VarietyNr"],
    });
    this.setState({ formVisible: true });
  };

  formUI = () => {
    if (!this.state.formVisible) return null;
    const { VarietyNr, MarkerID, CropCode, ExpectedResult, action } = this.state;
    const validation =
      VarietyNr === null || MarkerID === null || ExpectedResult === "" || CropCode === "";

    //fetch croplist
    if(this.props.crops.length === 0)
      this.props.getCropsFunc();

    return (
      <Wrapper>
        <div className='modalContent'>
          <div className='modalTitle'>
            <i className='demo-icon icon-plus-squared info' />
            <span>Marker Per Variety</span>
            <i
              role='presentation'
              className='demo-icon icon-cancel close'
              onClick={() => this.formVisibleFunc(false)}
              title='Close'
            />
          </div>
          {/* <div style={{display:'flex', flexDirection:'column'}}> */}
          <div className='modalBody'>
            <div>
              <label>Crop</label>
              {action === "i" && (
                <AutoSuggestion
                  name='CropCode'
                  placeholder='Crop'
                  change={this.filterCrops}
                  suggestList={this.state.crops}
                  setvalue={this.changeFunc}
                  triggerRenderFrom={0}
                />
              )}
              {action === "u" && (
                <input
                  type='text'
                  defaultValue={this.state.CropCode}
                  disabled
                />
              )}
            </div>

            <div>
              <label>Variety</label>
              {action === "i" && (
                <AutoSuggestion
                  name='VarietyNr'
                  placeholder='Variety'
                  change={(v) => this.getVarieties(v)}
                  suggestList={this.props.varieties}
                  setvalue={this.changeFunc}
                  triggerRenderFrom={2}
                />
              )}
              {action === "u" && (
                <input
                  type='text'
                  defaultValue={this.state.VarietyNr}
                  disabled
                />
              )}
            </div>

            <div></div>

            <div>
              <label>Marker</label>
              {action === "i" && (
                <AutoSuggestion
                  name='MarkerID'
                  placeholder='Marker'
                  change={(v) => this.getMarkers(v)}
                  suggestList={this.props.markers}
                  setvalue={this.changeFunc}
                  triggerRenderFrom={2}
                  checked={this.state.routineMarkersOnly}
                />
              )}
              {action === "u" && (
                <input
                  type='text'
                  defaultValue={this.state.MarkerID}
                  disabled
                />
              )}
            </div>

            <div className="customCheckbox">
              <input
                type="checkbox"
                id="routineMarkersOnly"
                name="routineMarkersOnly"
                checked={this.state.routineMarkersOnly}
                onChange={() => this.handleCheckboxChange()}
                disabled={action === "u"}
              />
              <label htmlFor="routineMarkersOnly">Routine Markers Only</label>{" "}
            </div>

            <div>
              <label>Result</label>
              <input
                type='text'
                name='ExpectedResult'
                value={this.state.ExpectedResult}
                onChange={this.handleChange}
              />
            </div>
            <div className='box1'>
              <label>Remarks</label>
              <textarea
                style={{
                  width: "100%",
                  height: "100px",
                  resize: "none",
                }}
                name='Remarks'
                onChange={this.handleChange}
                value={this.state.Remarks}
                maxLength='1024'
              />
            </div>
          </div>
          <div className='modalFooter'>
            <button onClick={this.submit} disabled={validation}>
              Save
            </button>
            <button onClick={() => this.formVisibleFunc(false)}>close</button>
          </div>
        </div>
      </Wrapper>
    );
  };

  getColumnSearchProps = (dataIndex) => ({
    filterDropdown: ({
      setSelectedKeys,
      selectedKeys,
      confirm,
      clearFilters,
    }) => {

      const nv = this.state.columns.filter((c) => {
        return c.ColumnID === dataIndex;
      });
      let fv = nv && nv[0] && nv[0].Label;
      fv = `Filter ${fv}`;

      return (
        <div style={{ padding: 8 }}>
          <Input
            ref={(node) => {
              this.searchInput = node;
            }}
            placeholder={fv}
            value={selectedKeys[0]}
            onChange={(e) =>
              setSelectedKeys(e.target.value ? [e.target.value] : [])
            }
            onPressEnter={() =>
              this.handleSearch(selectedKeys, confirm, dataIndex, nv[0].Label)
            }
            style={{ width: 188, marginBottom: 8, display: "block" }}
          />

          <Button
            type='primary'
            onClick={() =>
              this.handleSearch(selectedKeys, confirm, dataIndex, nv[0].Label)
            }
            icon={<FilterFilled />}
            size='small'
            style={{ width: 90, marginRight: 8 }}
          >
            Filter
          </Button>
          <Button
            className="btn-clear"
            onClick={() =>
              this.handleReset(clearFilters)
            }
            size='small'
            style={{ width: 90 }}
          >
            Clear
          </Button>
        </div>
      );
    },
    filterIcon: (filtered) => {
      return (
        <FilterFilled
          type='filter'
          style={{ color: filtered ? "#1890ff" : undefined }}
        />
      );
    },
    filteredValue: this.state.filter[dataIndex] ? this.state.filter[dataIndex] : null,
    filtered: this.state.filter[dataIndex] ? true : false,
    onFilter: (value, record) => {
      if (record[dataIndex] === null) return "";

      return record[dataIndex]
        .toString()
        .toLowerCase()
        .includes(value.toLowerCase());
    },
    onFilterDropdownVisibleChange: (visible) => {
      if (visible) {
        setTimeout(() => this.searchInput.select());
      }
    },
    render: (text) => text || "",
  });

  handleSearch = (selectedKeys, confirm, dataIndex, label) => {
    if (selectedKeys[0].trim() === "") return null;
    confirm();
    this.setState({
      searchText: selectedKeys[0],
      searchedColumn: dataIndex,
    });
  };

  handleTableChange = (pagination, filters, sorter, extra) => {
    const { page, size, filter, sortBy, sortOrder } = this.state;

    const pager = { ...this.state.pagination };
    pager.current = pagination.current;

    const newFilter = {};
    Object.keys(filters).map((m) => {
      if (filters[m] && filters[m][0]) {
        newFilter[m] = filters[m][0];
        return null;
      }
    });
    let newOrder = (sorter && sorter.order) || ""; //  || sortOrder || '';
    if (newOrder === "descend") newOrder = "desc";
    if (newOrder === "ascend") newOrder = "asc";

    const newSortBy =
      newOrder === "" ? "" : (sorter && sorter.field) || sortBy || "";

    const changedPage = pagination.pageSize || size;
    this.setState({
      pagination: { ...pagination },
      filter: newFilter,
      sortBy: newSortBy,
      sortOrder: newOrder,
    });

    this.props.fetchMarkerPerVariety(
      pagination.current,
      changedPage,
      newSortBy,
      newOrder,
      newFilter
    );

    if(size !== pagination.pageSize) {
      this.setState({
        size: pagination.pageSize
      });
      this.props.pageSizeChange(pagination.pageSize);
    }
    this.props.pageChange(pagination.current);
    this.props.filterChange(filters);
  };

  handleReset = (clearFilters) => {
    clearFilters();
    this.setState({ searchText: "" });
  };

  clearFilters = () => {
    this.setState({ filteredInfo: null });
    const { page, size } = this.state;
    this.props.empty();
    this.props.fetchMarkerPerVariety(page, size, "", "", {});
  };

  leftSection = () => {
    const { filter } = this.props;
    const filterLength =
      (Object.keys(filter).length === 0 || Object.values(filter).filter(o => o !== null).length === 0) && filter.constructor === Object;

    if (filterLength) return null;
    return <button onClick={this.clearFilters}>Clear Filter</button>;
  };

  rightSection = () => {
    return (
      <Fragment>
        <button
          className='with-i'
          onClick={() => this.formVisibleFunc(true)}
          disabled={!this.props.role}
        >
          <i className='demo-icon icon-plus-squared' />
          Add
        </button>
      </Fragment>
    );
  };

  render() {
    const { tblWidth, tblHeight, formVisible, total, pagination, size, filter  } = this.state;
    const customWidth = {
      CropCode: 85,
      Shortname: 150,
      MarkerFullName: 135,
      Action: 70,
      ExpectedResult: 157,
      ModifiedBy: 180,
      ModifiedOn: 150,
      VarietyNr: 154,
      Remarks: 250,
      StatusName: 92,
    };
    const tblConfig = { toAllBtn: false };
    const newCol = [];

    if (!false && this.props.columns.length) {
      this.props.columns.map((c) => {
        const { ColumnID, Label, IsVisible } = c;
        if (!IsVisible) return null;
        const fv = filter[ColumnID] ? filter[ColumnID] : "";

        const obj = {
          title: Label,
          dataIndex: ColumnID,
          key: ColumnID,
          width: customWidth[ColumnID],
          sorter: (a, b) => {},
          sortDirections: ["descend", "ascend"],
          ...this.getColumnSearchProps(ColumnID, fv),
        };
        if (ColumnID === "CropCode") {
          newCol.push({
            title: Label,
            dataIndex: ColumnID,
            key: ColumnID,
            width: customWidth[ColumnID] || 100,
            fixed: "left",
            sorter: (a, b) => {},
            sortDirections: ["descend", "ascend"],
            ...this.getColumnSearchProps(ColumnID, fv),
          });
          return null;
        }
        if (ColumnID === "Action") {
          newCol.push({
            title: Label,
            dataIndex: ColumnID,
            key: ColumnID,
            width: customWidth[ColumnID] || 100,
            fixed: "right",
            render: (text, record) => {
              const { StatusName, MarkerPerVarID } = record;
              const act = StatusName === "Active" ? "d" : "a";
              const color = StatusName === "Active" ? "#f44336" : "#8BC34A";
              return (
                <div>
                  <div style={{ display: "flex" }}>
                    {StatusName === "Active" ? (
                      <CloseCircleFilled
                        onClick={() => {
                          this.deleteFunc(MarkerPerVarID, act);
                        }}
                        style={{ fontSize: "18px", color }}
                      />
                    ) : (
                      <CheckCircleFilled
                        onClick={() => {
                          this.deleteFunc(MarkerPerVarID, act);
                        }}
                        style={{ fontSize: "18px", color }}
                      />
                    )}
                    &nbsp;&nbsp;
                    <EditFilled
                      onClick={() => {
                        this.editFunc(MarkerPerVarID);
                      }}
                      style={{ fontSize: "18px" }}
                    />
                  </div>
                </div>
              );
            },
          });
          return null;
        }
        newCol.push(obj);
        return null;
      });
    }

    return (
      <div>
        <ActionBar left={this.leftSection} right={this.rightSection} />
        <div className='container'>
          <br />
          <div>
            {/* <Table
              rowKey={(record) =>
                `${record.CropCode}-${record.ExpectedResult}-${record.MarkerID}-${record.VarietyNr}`
              }
              dataSource={this.state.data}
              size={this.state.data.length}
              columns={newCol}
              size='small'
              scroll={{ x: true, y: tblHeight - 180 }}
              pagination={false}

            /> */}
            <TblA
              data={this.state.data}
              columns={newCol}
              total={this.state.total}
              size={size}
              page={this.state.page}
              handleTableChange={this.handleTableChange}
              height={tblHeight}
              filter={filter}
              rowKey={"MarkerPerVarID"}
            />
          </div>
        </div>

        {this.formUI()}
      </div>
    );
  }
}

export default withAITracking(reactPlugin, MarkerPerVarietyComponent);
