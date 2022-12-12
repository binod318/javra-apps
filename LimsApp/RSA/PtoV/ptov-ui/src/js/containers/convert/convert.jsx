import React from 'react';
import { Link } from 'react-router-dom';
import PropTypes from 'prop-types';

import PHTable from '../../components/PHTable';
import Notification from '../../components/Notification';
import Loader from '../../components/Loader';

class Convert extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      fileSelected: props.fileSelected,
      plantList: props.plant,
      columnList: props.column,
      size: props.pageSize,
      page: props.pageNumber,
      filterList: props.filterList,
      sorting: props.sort,
      filterKey: '',
      loading: false,
      deleteList: [],
      fileStatus: props.fileStatus,
      fileList: props.files
    };
  }
  componentDidMount() {
    if (this.props.fileSelected !== '') {
      const {
        fileSelected,
        pageNumber,
        pageSize,
        filterList,
        sort
      } = this.props;
      this.props.fetchMain(
        fileSelected,
        pageNumber,
        pageSize,
        filterList,
        sort
      );

    }
  }
  componentWillReceiveProps(nextProps) {
    if (nextProps.status !== this.props.status) {
      const { convert, unmapcolumn } = nextProps.status;
      if (convert === 'procesing' || unmapcolumn === 'procesing') {
        this.setState({ loading: true });
      } else {
        this.setState({ loading: false });
      }
      if (unmapcolumn === 'success')
        this.setState({ deleteList: [] });
    }

    if (nextProps.plant !== this.props.plant) {
      this.setState({
        plantList: nextProps.plant
      });
    }
    if (nextProps.column !== this.props.column) {
      this.setState({
        columnList: nextProps.column
      });
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
    if (nextProps.sort !== this.props.sort) {
      this.setState({
        sorting: nextProps.sort
      });
    }
    if (nextProps.files !== this.props.files) {
      this.setState({
        fileList: nextProps.files
      });
    }
    if (nextProps.fileSelected !== this.props.fileSelected) {
      this.setState({ fileSelected: nextProps.fileSelected });
      const {
        fileSelected,
        pageNumber,
        pageSize,
        filterList,
        sort
      } = nextProps;
      this.props.fetchMain(
        fileSelected,
        pageNumber,
        pageSize,
        filterList,
        sort
      );
    }
    if (nextProps.fileStatus !== this.props.fileStatus) {
      this.setState({
        fileStatus: nextProps.fileStatus
      });
      const {
        fileSelected,
        pageNumber,
        pageSize,
        filterList,
        sort
      } = nextProps;
      this.props.fetchMain(
        fileSelected,
        pageNumber,
        pageSize,
        filterList,
        sort
      );
    }
  }

  filterKeySet = key => {
    this.setState({
      filterKey: key === this.state.filterKey ? '' : key
    });
  };
  filterSort = (key, direction, traitID) => {
    const { fileSelected, page, size, filterList, sorting } = this.state;

    let changeDirection = direction;
    let newKey = key;
    if (traitID !== null) {
      newKey = traitID;
    }
    if (sorting.name === newKey) {
      changeDirection = direction === 'asc' ? 'desc' : 'asc';
    } else {
      changeDirection = 'asc';
    }

    this.props.fetchMain(fileSelected, page, size, filterList, {
      name: newKey,
      direction: changeDirection
    });
  };
  filterAdd = obj => this.props.filterAdd(obj);
  filterRemove = name => this.props.filterRemove(name);
  filterClear = () => this.props.filterClear();

  changePage = pageNumber => {
    const { fileSelected, size, filterList, sorting } = this.state;
    this.props.fetchMain(fileSelected, pageNumber, size, filterList, sorting);
  };

  deleteListFun = (columnLabel, traitID, flag) => {
    const { deleteList } = this.state;
    if (flag) {
      deleteList.push({ columnLabel, traitID });
      this.setState({ deleteList: deleteList });
    } else {
      this.setState({
        deleteList: deleteList.filter(x => x.traitID != traitID)
      })
    }
  };

  finalDelete = () => {
    const { deleteList, fileSelected: cropCode } = this.state;
    const cols = deleteList.map(x => x.columnLabel).join(', ');
    if (confirm(`Do you want to delete column ${cols}?`))
      this.props.deleteColumn(cropCode, deleteList);
  };

  fileSelect = e => {
    const { target } = e;
    const { value } = target; // name
    this.props.selectReset();
    this.props.fileSelect(value);
  };

  fileStatusChange = (statusCode, name) => {
    const { dirty, dirtyMsg } = this.state;
    this.setState({ filterName: name });
    if (dirty) {
      if (confirm(dirtyMsg)) {
        this.setState({
          dirty: false,
          edited: false
        });
        this.props.fetchFileStatus(statusCode);
        this.props.selectReset();
      }
    } else {
      this.setState({
        selectRow: null
      });
      this.props.fetchFileStatus(statusCode);
      this.props.selectReset();
    }
  };

  render() {
    const { plantList, columnList, filterList, sorting, fileList, fileSelected, fileStatus } = this.state;
    const { loading, deleteList } = this.state;

    const filterValue = [
      { name: "Imported", statusCode: 100 },
      { name: "ToVarmas", statusCode: 200 },
      { name: "Stopped", statusCode: 300 },
      { name: "All", statusCode: 0 }
    ];

    return (
      <div className="convert">
        <div className="pageAction">
          <div className="selectForm">

              <select
                name="fileOption"
                value={fileSelected}
                onChange={this.fileSelect}
              >
                {fileList.map(file => (
                  <option key={file} value={file}>
                    {file}
                  </option>
                ))}
              </select>

              <div className="tapOption">
                <div className="radionButton">
                  {filterValue.map(data => {
                    const { name, statusCode } = data;
                    const match = fileStatus === statusCode;
                    return (
                      <label
                        key={name}
                        htmlFor={name}
                        className={match ? "active" : ""}
                      >
                        <i
                          className={
                            match ? "icon icon-circle" : "icon icon-circle-empty"
                          }
                        />
                        {name}
                        <input
                          id={name}
                          type="radio"
                          name="filterStatus"
                          value={statusCode}
                          checked={match}
                          onChange={() => this.fileStatusChange(statusCode, name)}
                        />
                      </label>
                    );
                  })}
                </div>
            </div>
            <div className="mainAction">
              <button
                className="wicon"
                title="Delete"
                disabled={deleteList.length === 0}
                onClick={this.finalDelete}
              >
                <i className="icon icon-trash" />
                Delete
              </button>
            </div>
          </div>
        </div>

        {columnList.length > 0 ? (
          <PHTable
            sub={40}
            selected={null} // eslint-disable-line
            filterList={filterList}
            plantList={plantList}
            columnList={columnList}
            sorting={sorting}
            total={this.props.total}
            page={this.props.pageNumber}
            size={this.props.pageSize}
            filterSort={this.filterSort}
            filterAdd={this.filterAdd}
            filterRemove={this.filterRemove}
            filterClear={this.filterClear}
            changePage={this.changePage}
            handleRowMouseDown={() => {}}
            handleDoubleClickItem={() => {}}
            onNewCropChange={() => {}}
            selectBlur={() => {}}
            deleteColumn={this.deleteListFun}
            deleteList={deleteList.length}
          />
        ) : (
          <div className="nomatch norow">
            <h3>No Records</h3>
          </div>
        )}

        {loading && <Loader />}
        <Notification where="convert" close={this.props.resetError} />
        <Notification where="unmapcolumn" close={this.props.resetError} />
      </div>
    );
  }
}

Convert.defaultProps = {
  fileSelected: '',
  plant: [],
  column: [],
  filterList: []
};
Convert.propTypes = {
  status: PropTypes.object.isRequired, // eslint-disable-line
  fileSelected: PropTypes.string, // eslint-disable-line
  plant: PropTypes.array, // eslint-disable-line
  column: PropTypes.array, // eslint-disable-line
  filterList: PropTypes.array, // eslint-disable-line
  sort: PropTypes.object, // eslint-disable-line

  pageSize: PropTypes.number.isRequired,
  pageNumber: PropTypes.number.isRequired,
  total: PropTypes.number.isRequired,

  fetchMain: PropTypes.func.isRequired,
  filterAdd: PropTypes.func.isRequired,
  filterRemove: PropTypes.func.isRequired,
  filterClear: PropTypes.func.isRequired,
  resetError: PropTypes.func.isRequired,
  deleteColumn: PropTypes.func.isRequired,
};

export default Convert;
