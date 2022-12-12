import React, { Fragment } from "react";
import { Input, Button, Checkbox } from "antd";
import { getDim } from "../../helpers/helper";
import ActionBar from "../../components/ActionBar/ActionBar";
import Wrapper from "../../components/Wrapper/wrapper";
import TblA from "../../components/TblA";
import {
  CloseCircleFilled,
  EditFilled,
  FilterFilled
} from "@ant-design/icons";
import { withAITracking } from '@microsoft/applicationinsights-react-js';
import { reactPlugin, appInsights } from '../../config/app-insights-service';

class CriteriaPerCropComponent extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      data: props.data,
      columns: props.columns,
      crops: props.crops,
      materialTypes: props.materialTypes,
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

      //popup state variables
      cropSelected: "",
      materialTypeSelected: "",
      ThresholdA: 0,
      ThresholdB: 0,
      CalcExternalAppHybrid: false,
      CalcExternalAppParent: false,
      action: "i"
    };
  }

  componentDidMount() {
    appInsights.trackPageView({ name: 'CriteriaPerCrop' });
    const { page, size, filter } = this.state;
    if (this.props.data.length === 0)
      this.props.fetchCriteriaPerCrop(page, size, "", "", filter);

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
    if (this.props.crops.length !== nextProps.crops.length) {
      this.setState({ crops: nextProps.crops });
    }
    if (this.props.materialTypes.length !== nextProps.materialTypes.length) {
      this.setState({ materialTypes: nextProps.materialTypes });
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
      cropSelected: "",
      materialTypeSelected: "",
      ThresholdA: 0,
      ThresholdB: 0,
      CalcExternalAppHybrid: false,
      CalcExternalAppParent: false,
      action: "i"
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

  handleBlur = (event) => {
    const {
      target: { name, value },
    } = event;
    //set default value 0
    if((name === 'ThresholdA' || name === 'ThresholdB') && value == ''){
      this.setState({
        [name]: 0,
      });
    }
  };

  handleCheckboxChange = (event) => {
    const {
      target: { name, checked },
    } = event;

    this.setState({
      [name]: checked,
    });
  };

  changeFunc = (name, id) => this.setState({ [name]: id });

  submit = () => {
    if (!this.props.role) return null;
    const {
      ThresholdA,
      ThresholdB,
      action,
      cropSelected: CropCode,
      materialTypeSelected: MaterialTypeID,
      CalcExternalAppHybrid,
      CalcExternalAppParent
    } = this.state;

    if (action === "u") {
      this.formVisibleFunc(false);
      this.props.postCriteriaPerCropFunc(
        CropCode,
        MaterialTypeID,
        ThresholdA,
        ThresholdB,
        CalcExternalAppHybrid,
        CalcExternalAppParent,
        action
      );
      return null;
    }
    this.props.postCriteriaPerCropFunc(
      CropCode,
      MaterialTypeID,
      ThresholdA,
      ThresholdB,
      CalcExternalAppHybrid,
      CalcExternalAppParent,
      action
    );
  };

  deleteFunc = (cropCode) => {
    if (!this.props.role) return null;

    if (confirm('Are you sure to delete?')) {
      this.props.postCriteriaPerCropFunc(cropCode, null, null, null, null, null, "d");
    }
  };

  editFunc = (CropCode) => {
    const selectedobj = this.state.data.find(
      (x) => x.CropCode === CropCode
    );
    this.setState({
      cropSelected: selectedobj.CropCode,
      materialTypeSelected: selectedobj.MaterialTypeID,
      ThresholdA: selectedobj.ThresholdA,
      ThresholdB: selectedobj.ThresholdB,
      CalcExternalAppHybrid: selectedobj.CalcExternalAppHybrid == 'True' ? true : false ,
      CalcExternalAppParent: selectedobj.CalcExternalAppParent == 'True' ? true : false,
      action: "u"
    });
    this.setState({ formVisible: true });
  };

  formUI = () => {
    if (!this.state.formVisible) return null;
    const { ThresholdA, ThresholdB, action, cropSelected, crops, materialTypes, CalcExternalAppHybrid, CalcExternalAppParent } = this.state;
    var threshA = parseFloat(ThresholdA);
    var threshB = parseFloat(ThresholdB);

    const validation =
      cropSelected == '' ||
      (threshA < 0 || threshB < 0 || isNaN(threshA) == true || isNaN(threshB) == true ) ||
      ((ThresholdA == 0 || ThresholdA == '' || ThresholdB == 0 || ThresholdB == '' ) && CalcExternalAppHybrid === false && CalcExternalAppParent === false);

    return (
      <Wrapper>
        <div className='modalContentCPC'>
          <div className='modalTitle'>
            <i className='demo-icon icon-plus-squared info' />
            <span>Criteria Per Crop</span>
            <i
              role='presentation'
              className='demo-icon icon-cancel close'
              onClick={() => this.formVisibleFunc(false)}
              title='Close'
            />
          </div>


          <div className='modalBody'>
            <div>
              <label>Crop</label>{/*eslint-disable-line*/}

              {action === "u" && (
                <input type="text" value={cropSelected} disabled />
              )}

              {action === "i" && (
                <select
                  name="cropSelected"
                  value={this.state.cropSelected}
                  onChange={this.handleChange}
                >
                  <option value="">Select</option>
                  {crops.map(crop => (
                    <option key={crop.CropCode} value={crop.CropCode}>
                      {crop.CropCode}
                    </option>
                  ))}
                </select>
              )}
            </div>

            <div>
              <label>Material Type</label>{/*eslint-disable-line*/}

              <select
                name="materialTypeSelected"
                value={this.state.materialTypeSelected}
                onChange={this.handleChange}
              >
                <option value="">Select</option>
                {materialTypes.map(materialType => (
                  <option key={materialType.MaterialTypeID} value={materialType.MaterialTypeID}>
                    {materialType.MaterialTypeCode}
                  </option>
                ))}
              </select>

            </div>

            <div>
              <label>ThresholdA</label>
              <input
                name='ThresholdA'
                type='text'
                defaultValue='0'
                value={this.state.ThresholdA}
                onChange={this.handleChange}
                onBlur={this.handleBlur}
              />
            </div>

            <div>
              <label>ThresholdB</label>
              <input
                name='ThresholdB'
                type='text'
                defaultValue='0'
                value={this.state.ThresholdB}
                onChange={this.handleChange}
                onBlur={this.handleBlur}
              />
            </div>

            <div>
              <label>Calculate External Hybrid</label>
              <Checkbox
                name='CalcExternalAppHybrid'
                checked={this.state.CalcExternalAppHybrid}
                onChange={this.handleCheckboxChange}
              />
            </div>

            <div>
              <label>Calculate External Parent</label>
              <Checkbox
                name='CalcExternalAppParent'
                checked={this.state.CalcExternalAppParent}
                onChange={this.handleCheckboxChange}
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

    this.props.fetchCriteriaPerCrop(
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
    this.props.fetchCriteriaPerCrop(page, size, "", "", {});
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
      CropCode: 100,
      MaterialTypeCode: 150,
      ThresholdA: 150,
      ThresholdB: 150,
      CalcExternalAppHybrid: 200,
      CalcExternalAppParent: 200,
      Action: 100
    };
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
              const { CropCode } = record;
              return (
                <div>
                  <div style={{ display: "flex" }}>
                    <CloseCircleFilled
                      onClick={() => {
                        this.deleteFunc(CropCode);
                      }}
                      style={{ fontSize: "18px", color: "#f44336" }}
                      title="delete"
                    />
                    &nbsp;&nbsp;
                    <EditFilled
                      onClick={() => {
                        this.editFunc(CropCode);
                      }}
                      style={{ fontSize: "18px" }}
                      title="edit"
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
            <TblA
              data={this.state.data}
              columns={newCol}
              total={this.state.total}
              size={size}
              page={this.state.page}
              handleTableChange={this.handleTableChange}
              height={tblHeight}
              filter={filter}
              rowKey={"CropCode"}
            />
          </div>
        </div>

        {this.formUI()}
      </div>
    );
  }
}

export default withAITracking(reactPlugin, CriteriaPerCropComponent);
