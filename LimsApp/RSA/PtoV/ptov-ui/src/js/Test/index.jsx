import React from 'react';
import { connect } from 'react-redux';

import PHTable from '../components/PHTable';

class Test extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      status: props.status,
      fileSelected: props.fileSelected,
      plantList: props.plant,
      columnList: props.column,
      size: props.pageSize,
      page: props.pageNumber,
      total: props.total,
      filterList: props.filterList,
      sorting: props.sort,
      filterKey: '',
      columnWidths: {}
    };
  }
  componentDidMount() {

    if(this.props.fileSelected !== '') {
      const { fileSelected, pageNumber, pageSize, filterList, sort } = this.props;
      this.props.fetchMain(fileSelected, pageNumber, pageSize, [], {
        name: '',
        direction: ''
      });
    }
    this.conversionCheck(this.props.column);
  }
  conversionCheck = cols => {
    if(cols.length) {
      cols.forEach(d => {
        if (d.refColumn !== null) {
          this.setState({
            convertable: false
          });
          return ;
        }
      });
    }
  };
  componentWillReceiveProps(nextProps) {
    if (nextProps.plant !== this.props.plant) {
      this.setState({
        plantList: nextProps.plant
      });
    }
    if (nextProps.column !== this.props.column) {
      this.setState({
        columnList: nextProps.column
      });
      this.conversionCheck(nextProps.column);
    }
    if (nextProps.filterList !== this.props.filterList) {
      this.setState({
        filterList: nextProps.filterList
      });

      this.props.fetchMain(
        nextProps.fileSelected,
        1,
        nextProps.pageSize,
        nextProps.filterList,
        nextProps.sort
      );
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
    if (nextProps.sort !== this.props.sort) {
      this.setState({
        sorting: nextProps.sort
      });
    }
  }

  fetchMain = () => {
    console.log('fatchMain')
  };
  filterAdd = obj => this.props.filterAdd(obj);
  filterRemove = name => this.props.filterRemove(name);
  filterClear = () => this.props.filterClear();
  filterSort = (key, direction, traitID) => {

    const { fileSelected, pageNumber, pageSize, filterList } = this.props;
    const { sorting } = this.state;

    let changeDirection = direction;
    let newKey = key;
    if (traitID !== null) {
      newKey = traitID
    }

    if (sorting.name === newKey) {
      changeDirection = direction === 'asc' ? 'desc' : 'asc';
    } else {
      changeDirection = 'asc';
    }
    this.props.fetchMain(fileSelected, pageNumber, pageSize, filterList, {
      name: newKey,
      direction: changeDirection
    });
  };

  changePage = pageNumber => {
    const { fileSelected, pageSize, filterList } = this.props;
    const { sorting } = this.state;
    this.props.fetchMain(fileSelected, pageNumber, pageSize, filterList, sorting);
  };

  render() {
    const { plantList, columnList, filterList, sorting } = this.state;
    const { fileSelected, dataScructure, columnWidths } = this.state;
    const { total, page, size, } = this.state;

    return (
      <div>
        hi projesh
        <PHTable
          sub={0}
          selected={fileSelected}
          filterList={filterList}
          plantList={plantList}
          columnList={columnList}
          sorting={sorting}

          size={size}
          page={page}
          total={total}

          filterSort={this.filterSort}
          filterAdd={this.filterAdd}
          filterRemove={this.filterRemove}
          filterClear={this.filterClear}
          changePage={this.changePage}
        />
      </div>
    );
  }
}

const mapState = state => ({
  status: state.status,

  fileSelected: 'TO',

  plant: state.convert.plant,
  column: state.convert.column,
  total: state.convert.total.total,
  pageNumber: state.convert.total.pageNumber,
  pageSize: state.convert.total.pageSize,

  filterList: state.convert.filter,
  sort: state.convert.sort,
});
const mapDispatch = dispatch => ({
  fetchMain: (fileName, pageNumber, pageSize, filter, sorting) => {
    dispatch({
      type: 'FETCH_CONVERT',
      fileName,
      pageNumber,
      pageSize,
      filter,
      sorting
    });
  },
  fetchData: (objectType, objectID, researchGroupID, pageSize) => {
    dispatch({
      type: 'IMPORT_PHENOME',
      objectType,
      objectID,
      cropID: researchGroupID,
      pageSize
    })
  },
  filterAdd: obj => {
    dispatch({
      type: 'FILTER_CONVERT_ADD',
      ...obj
    })
  },
  filterRemove: name => {
    dispatch({
      type: "FILTER_CONVERT_REMOVE",
      name: name
    });
  },
  filterClear: () => {
    dispatch({
      type: 'FILTER_CONVERT_CLEAR'
    });
  },
  resetError: () => {
    dispatch({
      type: 'RESET_ERROR'
    });
  }
});
export default connect(mapState, mapDispatch)(Test);
