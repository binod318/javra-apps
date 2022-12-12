import React, { Fragment } from "react";
import { Link } from "react-router-dom";
import uuidv4 from "uuid/v4";
import { Table, Input, Button, Divider, Tag } from "antd";
import { FileExcelFilled, EyeFilled, FilterFilled } from "@ant-design/icons";

import { getDim, dateValidRe, dateValidRe2 } from "../../helpers/helper";
import ActionBar from "../../components/ActionBar/ActionBar";
import TblA from "../../components/TblA";
import { withAITracking } from '@microsoft/applicationinsights-react-js';
import { reactPlugin, appInsights } from '../../config/app-insights-service';

class LabResultComponent extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      data: props.data,
      columns: props.columns,
      tblWidth: 900,
      tblHeight: 600,
      page: props.page,
      size: 50,
      pagination: {
        current: props.page,
      },
      filter: props.filter || {},
      total: props.total,
      sortBy: props.sorter.sortBy || "",
      sortOrder: props.sorter.sortOrder || "",

      searchText: "",
      searchedColumn: "",
    };
    this.dateLab = ["Exp Ready"];
  }

  componentDidMount() {
    appInsights.trackPageView({ name: 'LabResult' });
    const { page, size, filter, sortBy, sortOrder } = this.state;

    const newFilter = {};
    Object.keys(filter).map((m) => {
      if (filter[m] && filter[m] != '') {
        newFilter[m] = filter[m][0];
        return null;
      }
    });

    this.props.labResultFetch(page, size, sortBy, sortOrder, newFilter);

    window.addEventListener("beforeunload", this.handleWindowClose);
    window.addEventListener("resize", this.updateDimensions);
    this.updateDimensions();
    window.addEventListener("resize", this.updateDimensions);
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.data) {
      this.setState({ data: nextProps.data });
      this.updateDimensions();
    }
    if (nextProps.columns.length) {
      this.setState({ columns: nextProps.columns });
      this.updateDimensions();
    }

    if (nextProps.filter) {
      this.setState({ filter: nextProps.filter });
    }

    if (nextProps.sorter) {
      this.setState({ sortBy: nextProps.sorter.sortBy, sortOrder: nextProps.sorter.sortOrder });
    }

    if (nextProps.total !== this.props.total) {
      this.setState({ total: nextProps.total });
    }
    if (nextProps.page !== this.props.page) {
      this.setState({ page: nextProps.page });
    }
  }

  componentWillUnmount() {
    window.removeEventListener("beforeunload", this.handleWindowClose);
    window.removeEventListener("resize", this.updateDimensions);

    if (!this.props.history.location.pathname.includes('lab_result')) {
      this.props.empty();
    }
  }

  updateDimensions = () => {
    const { width: tblWidth, height: tblHeight } = getDim();
    this.setState({ tblWidth, tblHeight });
  };
  handleWindowClose = (e) => {
    if (this.props.isChange) {
      e.returnValue = "blocked";
    }
  };

  changeYear = (e) => {
    this.props.labResultYearSelect(e.target.value);
  };
  changePeriod = (e) => {
    const row = this.state.period.find((t) => t.PeriodID == e.target.value);
    this.props.labResultPeriodSelect(e.target.value, row);
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
      let fv = (nv && nv[0] && nv[0].Label) || "";
      fv = `Filter ${fv}`;
      if (nv && nv[0] && this.dateLab.includes(nv[0].Label)) {
        fv = "dd/mm/yyyy";
      }
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
            onClick={() => this.handleReset(clearFilters)}
            size='small'
            style={{ width: 90 }}
          >
            Clear
          </Button>
        </div>
      );
    },
    filterIcon: (filtered) => (
      <FilterFilled type='filter' style={{ color: filtered ? "#1890ff" : undefined }} />
    ),
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
    render: text => text,
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
    this.props.labResultFetch(
      pagination.current,
      changedPage,
      newSortBy,
      newOrder,
      newFilter
    );
    this.props.pageChange(pagination.current);
    this.props.filterChange(filters);
    this.props.sortChange({sortBy: newSortBy, sortOrder: newOrder});
  };
  handleReset = (clearFilters) => {
    clearFilters();
    this.setState({ searchText: "" });
  };

  clearFilters = () => {
    this.setState({ filteredInfo: null });
    const { page, size, filter } = this.state;
    this.props.empty();
    this.props.labResultFetch(page, size, "", "", {});
  };
  rightSection = () => {
    const { filter } = this.props;
    const filterLength =
      Object.keys(filter).length === 0 && filter.constructor === Object
    if (filterLength) return null;
    return <button onClick={this.clearFilters}>Clear Filter</button>;
  }

  rowClassName = (rowData, rowIndex) => {
    if(rowData["IsLabPriority"] == 1)
      return "lab-prio";

    return "";
  };

  render() {
    const customWidth = {
      CropCode: 80,
      DetAssignmentID: 120,
      SampleNr: 120,
      BatchNr: 110,
      Shortname: 260,
      Status: 100,
      Plates: 240,
      ExpectedReadyDate: 140,
      Folder: 100,
      QualityClass: 110,
      Action: 60,
    };
    const {
      tblHeight,
      tblWidth,
      columns,
      data,
      total,
      size,
      page,
      filter,
      pagination,
      sortBy,
      sortOrder
    } = this.state;

    const newCol = [];
    if (columns.length) {
      columns.map((c) => {
        const { ColumnID, Label, IsVisible } = c;
        if (!IsVisible) return null;

        const obj = {
          title: Label,
          dataIndex: ColumnID,
          key: ColumnID,
          width: customWidth[ColumnID] || 100,
          sorter: true,
          sortDirections: ["descend", "ascend"],
          sortOrder: ColumnID == sortBy ? sortOrder + 'end' : null,
          ...this.getColumnSearchProps(ColumnID),
        };

        if (ColumnID === "Action") {
          newCol.push({
            title: Label,
            dataIndex: ColumnID,
            key: ColumnID,
            width: customWidth[ColumnID] || 100,
            fixed: "right",
            render: (text, record) => (
              <div align='center'>
                <Link to={`lab_result/${record.DetAssignmentID}`}>
                  <EyeFilled />
                </Link>
              </div>
            ),
          });
          return null;
        }
        newCol.push(obj);
        return null;
      });
    }
    const changedPage = pagination.pageSize || size;

    const computedHeight = tblHeight ? tblHeight - 200 : 600;
    return (
      <div>
        <ActionBar left={this.rightSection} />
        <div className='container'>
          <br />
          <div>
            <TblA
              data={this.state.data}
              columns={newCol}
              total={this.state.total}
              size={changedPage}
              page={this.state.page}
              handleTableChange={this.handleTableChange}
              height={tblHeight}
              filter={filter}
              rowKey='DetAssignmentID'
              rowClassName={this.rowClassName}
            />
          </div>
        </div>
      </div>
    );
  }
}

export default withAITracking(reactPlugin, LabResultComponent);
