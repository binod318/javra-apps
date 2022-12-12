import React from 'react';
import PropTypes from 'prop-types';

import Result from './result';
// import List from './CheckList';
import { getDim } from '../../helpers/helper';
import PHTable from '../../components/PHTable';

class RDTResultComponent extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      tblWidth: 0,
      tblHeight: 0,
      resultList: props.result,
      mode: '',
      editNode: {},

      localFilter: props.filter
    };
  }
  componentDidMount() {
    const { pagenumber, pagesize, filter } = this.props;
    this.props.fetchData(pagenumber, pagesize, filter);
    window.addEventListener('resize', this.updateDimensions);
    this.updateDimensions();
  }
  componentWillReceiveProps(nextProps) {
    if (nextProps.result) {
      this.setState({
        resultList: nextProps.result
      });
      this.updateDimensions();
    }
  }
  componentWillUnmount() {
    window.removeEventListener('resize', this.updateDimensions);
  }

  onAddResult = obj => {
    const { pagesize, filter } = this.props;
    this.props.resultChanges(obj.cropCode, obj.data, 1, pagesize, filter);
  };

  onDeleteResult = (id, crop) => {
    const removeObj = {
      cropCode: crop,
      data: [{ id, action: 'D' }]
    };
    const confirmValue = confirm('Do you want to remove this Result mapping ?'); // eslint-disable-line
    if (confirmValue) {
      this.onAddResult(removeObj);
    }
  };

  onUpdateResult = id => {
    const editNode = this.state.resultList.find((result, i) => i === id);

    this.setState({
      editNode,
      mode: 'edit'
    });
  };

  filterFetch = () => {
    const { pagesize } = this.props;
    const { localFilter } = this.state;
    this.props.fetchData(1, pagesize, localFilter);
  };

  filterClear = () => {
    this.props.filterClear();
    const { pagesize } = this.props;
    this.setState({ localFilter: [] });
    this.props.fetchData(1, pagesize, []);
  };

  pageClick = pg => {
    const { pagesize, filter } = this.props;
    this.props.fetchData(pg, pagesize, filter);
  };

  updateDimensions = () => {
    const dim = getDim();
    this.setState({
      tblWidth: dim.width,
      tblHeight: dim.height
    });
  };

  mode = mode => {
    this.setState({
      mode,
      editNode: mode === '' ? {} : this.state.editNode
    });
  };

  filterClearUI = () => {
    const { filter: filterLength } = this.props;
    if (filterLength < 1) return null;
    return (
      <button className="with-i" onClick={this.filterClear}>
        <i className="icon icon-cancel" />
        Filters
      </button>
    );
  };

  formUI = () => {
    const { mode, editNode } = this.state;
    if (mode === '') return null;
    if (mode === 'add') {
      return (
        <Result
          close={this.mode}
          mode={mode}
          editData={editNode}
          onAppend={this.onAddResult}
        />
      );
    }
    return (
      <Result
        close={this.mode}
        mode={mode}
        editData={editNode}
        onAppend={this.onAddResult}
      />
    );
  };

  localFilterAdd = (name, value) => {
    const { localFilter } = this.state;

    const obj = {
      name,
      value,
      expression: 'contains',
      operator: 'and',
      dataType: 'NVARCHAR(255)'
    };

    const check = localFilter.find(d => d.name === obj.name);
    let newFilter = '';
    if (check) {
      newFilter = localFilter.map(item => {
        if (item.name === obj.name) {
          return { ...item, value: obj.value };
        }
        return item;
      });
      this.setState({ localFilter: newFilter });
    } else {
      this.setState({ localFilter: localFilter.concat(obj) });
    }
  };

  render() {
    const { tblHeight, tblWidth } = this.state;
    const calcTblHeight = tblHeight - 125;

    const columns = [
      'crop',
      'materialStatus',
      'trait',
      'traitValue',
      'percentFrom',
      'percentTo',
      'mappingCol',
      'determination',
      'value',
      'Action'
    ];
    const columnsMapping = {
      crop: { name: 'Crop', filter: true, fixed: true },
      materialStatus: { name: 'Material Status', filter: true, fixed: true },
      trait: { name: 'Trait', filter: true, fixed: true },
      traitValue: { name: 'Trait Value', filter: true, fixed: true },
      percentFrom: { name: 'Percent From', filter: true, fixed: true },
      percentTo: { name: 'Percent To', filter: true, fixed: true },
      mappingCol: { name: 'Mapping Col', filter: true, fixed: true },
      determination: { name: 'Determination', filter: true, fixed: true },
      value: { name: 'Value', filter: true, fixed: true },
      Action: { name: 'Action', filter: false, fixed: false }
    };
    const columnsWidth = {
      crop: 60,
      materialStatus: 140,
      percentFrom: 160,
      percentTo: 160,
      mappingCol: 160,
      trait: 140,
      traitValue: 160,
      determination: 160,
      value: 160,
      Action: 90
    };

    return (
      <div className="traitContainer">
        <section className="page-action">
          <div className="left"> {this.filterClearUI()} </div>
          <div className="right">

            {this.props.role.includes('managemasterdatautm') && (
              <button className="with-i" onClick={() => this.mode('add')}>
                <i className="icon icon-plus-squared" />
                Add Result
              </button>
            )}

          </div>
        </section>

        <div className="container">
          <PHTable
            sideMenu={this.props.sideMenu}
            filter={this.props.filter}
            tblWidth={tblWidth}
            tblHeight={calcTblHeight}
            columns={columns}
            data={this.props.result}
            pagenumber={this.props.pagenumber}
            pagesize={this.props.pagesize}
            total={this.props.total}
            pageChange={this.pageClick}
            columnsMapping={columnsMapping}
            columnsWidth={columnsWidth}
            filterAdd={this.props.filterAdd}
            filterFetch={this.filterFetch}
            filterClear={this.filterClear}
            localFilterAdd={this.localFilterAdd}
            localFilter={this.state.localFilter}
            role={this.props.role}
            actions={{
              name: 'rdt_result',
              add: () => {},
              edit: this.onUpdateResult,
              delete: this.onDeleteResult
            }}
          />
        </div>
        {this.formUI()}
      </div>
    );
  }
}
RDTResultComponent.defaultProps = {
  result: [],
  total: 0,
  filter: []
};
RDTResultComponent.propTypes = {
  result: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  total: PropTypes.number,
  pagenumber: PropTypes.number.isRequired,
  pagesize: PropTypes.number.isRequired,
  filter: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  fetchData: PropTypes.func.isRequired,
  sideMenu: PropTypes.bool.isRequired,
  filterAdd: PropTypes.func.isRequired,
  filterClear: PropTypes.func.isRequired,
  resultChanges: PropTypes.func.isRequired
};
export default RDTResultComponent;
