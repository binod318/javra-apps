import React, { Component } from 'react';
import PropTypes from 'prop-types';
import Wrapper from '../../components/Wrapper';
import Loader from '../../components/Loader';
import Notification from '../../components/Notification';

import PVTable from '../../components/PVTable';
import AddForm from './addForm';
import EditForm from './editForm';

class Attribute extends Component {
  constructor(props) {
    super(props);
    this.state = {
      resultList: props.result,
      size: props.pageSize,
      page: props.pageNumber,
      total: props.total,
      filterList: props.filterList,
      sorting: props.sort,
      selected: null,
      mode: '',
      columnWidths: {
        cropCode: 100,
        traitName: 180,
        traitValue: 150,
        sfColumnLabel: 170,
        screeningValue: 180,
        Action: 70
      },

      loading: false
      
    };
  }
  componentDidMount() {
    const { pageNumber, pageSize, filterList, sort } = this.props;
    this.props.fetchDate(pageNumber, pageSize, filterList, sort);
  }
  componentWillReceiveProps(nextProps) {
    if (nextProps.status) {
      if (nextProps.status.result === 'success') {
        this.setState({ mode: '', selected: null });
      }
      if (
        nextProps.status.result === 'procesing' ||
        nextProps.status.initial === 'procesing' ||
        nextProps.status.relation === 'procesing'
      ) {
        this.setState({ loading: true });
      } else {
        this.setState({ loading: false });
      }
    }
    
    if (nextProps.result !== this.props.result) {
      this.setState({
        resultList: nextProps.result
      });
    }
    if (nextProps.pageSize !== this.props.pageSize) {
      this.setState({
        size: nextProps.pageSize
      });
    }
    if (nextProps.pageNumber !== this.props.pageNumber) {
      this.setState({
        page: nextProps.pageNumber
      });
    }
    if (nextProps.total !== this.props.total) {
      this.setState({
        total: nextProps.total
      });
    }
    if (nextProps.filterList !== this.props.filterList) {
      this.setState({
        filterList: nextProps.filterList
      });
      this.props.fetchDate(
        1,
        this.props.pageSize,
        nextProps.filterList,
        nextProps.sort
      );
    }
    if (nextProps.sort !== this.props.sort) {
      this.setState({
        sorting: nextProps.sort
      });
    }
  }

  filterData = () => {
    const { pageSize, filter } = this.props;
    this.props.fetchDate(1, pageSize, filter);
  };
  filterSort = (key, direction) => {
    let newDirection = 'asc';
    const { pageNumber, pageSize, filterList } = this.props;
    const { sorting } = this.state;
    if (sorting.name === key) {
      newDirection = direction === 'asc' ? 'desc' : 'asc';
    } else {
      newDirection = 'asc';
    }
    this.props.fetchDate(pageNumber, pageSize, filterList, {
      name: key,
      direction: newDirection
    });
  };
  filterAdd = obj => this.props.filterAdd(obj);
  filterRemove = name => this.props.filterRemove(name);
  filterClear = () => this.props.filterClear();

  changePage = pageNumber => {
    const { pageSize, filterList } = this.props;
    const { sorting } = this.state;
    this.props.fetchDate(pageNumber, pageSize, filterList, sorting);
  };

  dataEdit = id => {
    const { resultList } = this.state;
    this.setState({
      mode: 'edit',
      selected: resultList[id]
    });
  };

  dataDelete = traitScrResultID => {
    const obj = {
      traitScreeningScreeningValues: [
        {
          traitScrResultID,
          action: 'D'
        }
      ],
      pageNumber: 1, // this.props.pageNumber,
      pageSize: this.props.pageSize,
      filter: this.props.filterList,
      sorting: this.props.sort
    };
    if (confirm('Are you sure you want to delete Trait Screening Result.')) {  // eslint-disable-line
      this.props.relationChange(obj);
    }
  };

  dataStructure = {
    cropCode: { name: 'Crop', width: 60, grow: 0, sort: true, filter: true },
    traitName: {
      name: 'Trait Name',
      width: 160,
      grow: 1,
      sort: true,
      filter: true
    },
    traitValue: {
      name: 'Trait Value',
      width: 180,
      grow: 0,
      sort: true,
      filter: true
    },
    sfColumnLabel: {
      name: 'Screening Field',
      width: 160,
      grow: 0,
      sort: true,
      filter: true
    },
    screeningValue: {
      name: 'Screening Value',
      width: 160,
      grow: 0,
      sort: true,
      filter: true
    },
    Action: { name: 'Action', width: 70, grow: 0, sort: false, filter: false }
  };

  close = () => {
    this.setState({ mode: '', selected: null });
    this.props.resetError();
  };

  pageActionUI = () => (
    <div className="pageAction">
      <div className="selectForm">
        <div />
        <div className="mainAction">
          <button
            title="Add Trait Screening Value"
            className="wicon"
            onClick={() => this.setState({ mode: 'add' })}
          >
            <i className="icon icon-plus-circle" />
            <span>Add</span>
          </button>
        </div>
      </div>
    </div>
  );

  modelDisplayUI = () => {
    const { mode, page, size, sorting, filterList, selected } = this.state;

    if (mode === 'add') {
      return (
        <Wrapper display={mode}>
          <AddForm
            page={page}
            size={size}
            filter={filterList}
            sorting={sorting}
            close={this.close}
          />
        </Wrapper>
      );
    }
    if (mode === 'edit') {
      return (
        <Wrapper display={mode}>
          <EditForm
            record={selected}
            page={page}
            size={size}
            filter={filterList}
            sorting={sorting}
            close={this.close}
          />
        </Wrapper>
      );
    }
    return null;
  };

  render() {
    const { loading, resultList, filterList } = this.state;
    const { page, size, total, sorting, columnWidths } = this.state;
    const value = true;

    return (
      <div className="result">
        {this.pageActionUI()}
        {value ? (
          <PVTable
            sub={45}
            data={resultList}
            total={total}
            page={page}
            size={size}
            filterList={filterList}
            structure={this.dataStructure}
            columnWidths={columnWidths}
            filterSort={this.filterSort}
            sorting={sorting}
            filterData={() => this.filterData()}
            filterAdd={this.filterAdd}
            filterRemove={this.filterRemove}
            filterClear={this.filterClear}
            changePage={this.changePage}
            dataEdit={this.dataEdit}
            dataDelete={this.dataDelete}
          />
        ) : (
          <div className="pageLoader">
            <h1>Loading...</h1>
          </div>
        )}
        {this.modelDisplayUI()}

        {loading && <Loader />}
        <Notification where="result" close={this.props.resetError} />
      </div>
    );
  }
}
Attribute.defaultProps = {
  status: {},
  sort: {},
  resultList: [],
  result: [],
  filterList: [],
  pageSize: 1,
  pageNumber: 1,
  total: 0,
};
Attribute.propTypes = {
  status: PropTypes.object, // eslint-disable-line
  sort: PropTypes.object, // eslint-disable-line
  filterList: PropTypes.array, // eslint-disable-line
  filter: PropTypes.array, // eslint-disable-line
  filterAdd: PropTypes.func.isRequired,
  filterRemove: PropTypes.func.isRequired,
  filterClear: PropTypes.func.isRequired,
  relationChange: PropTypes.func.isRequired,
  resetError: PropTypes.func.isRequired,
  fetchDate: PropTypes.func.isRequired,
  resultList: PropTypes.array, // eslint-disable-line
  result: PropTypes.array, // eslint-disable-line
  pageSize: PropTypes.number,
  pageNumber: PropTypes.number,
  total: PropTypes.number,
};

export default Attribute;
