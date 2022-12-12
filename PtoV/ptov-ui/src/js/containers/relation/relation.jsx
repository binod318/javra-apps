import React from 'react';
import PropTypes from 'prop-types';

import Notification from '../../components/Notification';
import Wrapper from '../../components/Wrapper';
import Loader from '../../components/Loader';
import PVTable from '../../components/PVTable';
import EditForm from './editForm';

class Relation extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      relationList: props.relation,
      size: props.pageSize,
      page: props.pageNumber,
      total: props.total,
      filterList: props.filterList,
      sorting: props.sort,
      selected: null,
      mode: '',
      columnWidths: {
        cropCode: 100,
        traitName: 100,
        sfColumnLabel: 160,
        sameValue: 140,
        Action: 70
      },
      loading: false
    };
  }
  componentDidMount() {
    const { pageNumber, pageSize, filterList, sort: sorting } = this.props;
    this.props.fetchDate(pageNumber, pageSize, filterList, sorting);
  }
  componentWillReceiveProps(nextProps) {
    if (nextProps.status !== this.props.status) {
      if (
        nextProps.status.update === 'procesing' ||
        nextProps.status.relation === 'procesing'
      ) {
        this.setState({ loading: true });
      } else {
        this.setState({ loading: false });
      }
      if (nextProps.status.update === 'success') {
        this.setState({ mode: '', selected: null });
      }
    }
    if (nextProps.relation !== this.props.relation) {
      this.setState({
        relationList: nextProps.relation
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
    const { pageSize, filterList } = this.props;
    this.props.fetchDate(1, pageSize, filterList);
  };

  filterSort = (key, direction) => {
    const { pageNumber, pageSize, filterList } = this.props;
    const { sorting } = this.state;
    let changeDirection = direction;
    if (sorting.name === key) {
      changeDirection = direction === 'asc' ? 'desc' : 'asc';
    } else {
      changeDirection = 'asc';
    }

    this.props.fetchDate(pageNumber, pageSize, filterList, {
      name: key,
      direction: changeDirection
    });
  };
  filterAdd = obj => {
    this.props.filterAdd(obj);
  };
  filterRemove = name => this.props.filterRemove(name);
  filterClear = () => this.props.filterClear();

  changePage = pageNumber => {
    const { pageSize, filterList } = this.props;
    const { sorting } = this.state;
    this.props.fetchDate(pageNumber, pageSize, filterList, sorting);
  };

  dataEdit = id => {
    const { relationList } = this.state;
    this.setState({
      mode: 'edit',
      selected: relationList[id]
    });
  };
  dataUpdate = (screeningFieldID, sameValue) => {
    const {
      selected,
      page: pageNumber,
      size: pageSize,
      filterList: filter,
      sorting
    } = this.state;
    const { traitScreeningID, cropTraitID } = selected;
    const action = traitScreeningID === null ? 'I' : 'U';
    const obj = {
      traitScreeningRelation: [
        {
          traitScreeningID: traitScreeningID || 0,
          screeningFieldID,
          cropTraitID,
          sameValue,
          action
        }
      ],
      pageNumber,
      pageSize,
      filter,
      sorting
    };
    this.props.relationChange(obj);
  };
  dataDelete = traitScreeningID => {
    const {
      page: pageNumber,
      size: pageSize,
      filterList: filter,
      sorting
    } = this.state;
    const obj = {
      traitScreeningRelation: [
        {
          traitScreeningID,
          action: 'D'
        }
      ],
      pageNumber,
      pageSize,
      filter,
      sorting
    };

    if (confirm('Are you sure you want to delete Trait Screening Relation.')) {  // eslint-disable-line
      this.props.relationChange(obj);
    }
  };

  dataStructure = {
    cropCode: { name: 'Crop', grow: 0, sort: true, filter: true, width: 160 },
    traitName: { name: 'Trait', grow: 1, sort: true, filter: true, width: 100 },
    sfColumnLabel: {
      name: 'Screening Field',
      grow: 1,
      sort: true,
      filter: true,
      width: 160
    },
    sameValue: {
      name: 'Same Value',
      grow: 0,
      sort: true,
      filter: false,
      width: 100
    },
    Action: { name: 'Action', grow: 0, sort: false, filter: false, width: 70 }
  };

  close = () => {
    this.props.resetError();
    this.setState({ mode: '', selected: null });
  };

  formUI = () => {
    const { mode, selected } = this.state;
    return (
      <Wrapper display={mode}>
        <EditForm record={selected} close={this.close} edit={this.dataUpdate} />
      </Wrapper>
    );
  };

  render() {
    const {
      loading,
      relationList,
      page,
      size,
      total,
      filterList,
      mode,
      sorting,
      columnWidths
    } = this.state;

    return (
      <div>
        <PVTable
          sub={0}
          data={relationList}
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

        {this.formUI()}
        {loading && <Loader />}

        {mode !== 'edit' && (
          <Notification where="relation" close={this.props.resetError} />
        )}
      </div>
    );
  }
}

Relation.propTypes = {
  status: PropTypes.object.isRequired, // eslint-disable-line
  relation: PropTypes.array.isRequired, // eslint-disable-line
  total: PropTypes.number.isRequired,
  pageNumber: PropTypes.number.isRequired,
  pageSize: PropTypes.number.isRequired,
  filterList: PropTypes.array.isRequired, // eslint-disable-line
  sort: PropTypes.object.isRequired, // eslint-disable-line
  fetchDate: PropTypes.func.isRequired,
  relationChange: PropTypes.func.isRequired,
  filterAdd: PropTypes.func.isRequired,
  filterRemove: PropTypes.func.isRequired,
  filterClear: PropTypes.func.isRequired,
  resetError: PropTypes.func.isRequired
};
export default Relation;
