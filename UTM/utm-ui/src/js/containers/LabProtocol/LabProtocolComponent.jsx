import React from 'react';
import PropTypes from 'prop-types';
import { getDim } from '../../helpers/helper';
import PHTable from '../../components/PHTable';
import FormComponent from './FormComponent';

class LabProtocol extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      tblWidth: 0,
      tblHeight: 0,
      checkVisibility: false,
      mode: '',
      editNode: {},
      localFilter: props.filter
    };
  }

  componentDidMount() {
    const { pagenumber, pagesize, filter } = this.props;
    this.props.fetchProtocol(pagenumber, pagesize, filter);
    window.addEventListener('resize', this.updateDimensions);
    this.updateDimensions();
  }

  componentWillUnmount() {
    window.removeEventListener('resize', this.updateDimensions);
  }

  updateDimensions = () => {
    const dim = getDim();
    this.setState({
      tblWidth: dim.width,
      tblHeight: dim.height
    });
  };
  pageClick = pg => {
    const { pagesize, filter } = this.props;
    this.props.fetchProtocol(pg, pagesize, filter);
  };
  filterFetch = () => {
    const { pagesize } = this.props;
    const { localFilter } = this.state;
    this.props.fetchProtocol(1, pagesize, localFilter);
  };
  filterClear = () => {
    this.props.filterClear();
    const { pagesize } = this.props;
    this.setState({ localFilter: [] });
    this.props.fetchProtocol(1, pagesize, []);
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
  addButtonUI = () => (
    <button className="with-i" onClick={() => this.visibility(true)}>
      <i className="icon icon-plus-squared" />
      Add Protocol
    </button>
  );

  visibility = flag => {
    if (!flag) {
      this.setState({
        editNode: {}
      });
    }
    this.setState({
      checkVisibility: flag,
      mode: ''
    });
  };
  edit = id => {
    const { result } = this.props;

    this.setState({
      editNode: result[id],
      mode: 'edit',
      checkVisibility: true
    });
  };
  formUI = () => {
    const { mode, checkVisibility, editNode } = this.state;
    return checkVisibility ? (
      <FormComponent mode={mode} editData={editNode} close={this.visibility} />
    ) : null;
  };

  validateAdd = () => {};

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

    // 'id',
    const columns = [
      'cropCode',
      'materialTypeName',
      'testTypeName',
      'testProtocolName',
      'Action'
    ];
    const columnsMapping = {
      id: { name: 'ID', filter: false, fixed: false },
      cropCode: { name: 'Crop Code', filter: true, fixed: false },
      materialTypeName: { name: 'Material Type', filter: true, fixed: true },
      testTypeName: { name: 'Test Type', filter: true, fixed: true },
      testProtocolName: { name: 'Test Protocol', filter: true, fixed: true },
      Action: { name: 'Action', filter: false, fixed: false }
    };
    const columnsWidth = {
      id: 160,
      cropCode: 160,
      materialTypeName: 160,
      testTypeName: 60,
      testProtocolName: 160,
      Action: 90
    };

    return (
      <div className="traitContainer">
        <section className="page-action">
          <div className="left"> {this.filterClearUI()} </div>
          <div className="right"> {this.addButtonUI()} </div>
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
            filterFetch={this.filterFetch}
            filterClear={this.filterClear}
            filterAdd={this.props.filterAdd}
            localFilterAdd={this.localFilterAdd}
            localFilter={this.state.localFilter}
            actions={{
              name: 'protocol',
              edit: this.edit
            }}
          />
        </div>
        {this.formUI()}
      </div>
    );
  }
}
LabProtocol.defaultProps = {
  filter: [],
  result: []
};
LabProtocol.propTypes = {
  fetchProtocol: PropTypes.func.isRequired,
  filterClear: PropTypes.func.isRequired,
  filterAdd: PropTypes.func.isRequired,
  pagenumber: PropTypes.number.isRequired,
  pagesize: PropTypes.number.isRequired,
  total: PropTypes.number.isRequired,
  sideMenu: PropTypes.bool.isRequired,
  result: PropTypes.array, // eslint-disable-line
  filter: PropTypes.array // eslint-disable-line
};
export default LabProtocol;
