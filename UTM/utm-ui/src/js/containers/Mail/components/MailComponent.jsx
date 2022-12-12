import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';

import Result from './Result';
import { getDim } from '../../../helpers/helper';
import PHTable from '../../../components/PHTable';

class MailComponent extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      tblWidth: 0,
      tblHeight: 0,
      data: props.email,
      total: props.total,
      pagesize: props.pagesize,
      pagenumber: props.pagenumber,
      refresh: props.refresh, // eslint-disable-line
      breedingStation: props.breedingStation,
      mode: '',
      editNode: {},
      localFilter: props.filter
    };
  }

  componentDidMount() {
    window.addEventListener('resize', this.updateDimensions);
    this.updateDimensions();

    //get selected menu
    let selectedMenu = window.localStorage.getItem("selectedMenuGroup");

    //if menu is not set then set default menu(Utm general) from here
    if(!selectedMenu || selectedMenu == '') {
      selectedMenu = 'utmGeneral';
      window.localStorage.setItem("selectedMenuGroup", selectedMenu);
    }

    this.props.fetchMail(this.props.pagenumber, this.props.pagesize, selectedMenu);
    if (this.props.breedingStation.length === 0) {
      this.props.fetchBreeding();
    }
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.refresh !== this.props.refresh) {
      this.setState({ data: nextProps.email });
    }
    if (nextProps.breedingStation) {
      this.setState({ breedingStation: nextProps.breedingStation });
    }
    if (nextProps.total !== this.props.total) {
      this.setState({ total: nextProps.total });
    }
    if (nextProps.pagenumber !== this.props.pagenumber) {
      this.setState({ pagenumber: nextProps.pagenumber });
    }
    if(nextProps.selectedMenu !== this.props.selectedMenu && nextProps.selectedMenu !== '') {
      this.props.fetchMail(this.props.pagenumber, this.props.pagesize, nextProps.selectedMenu);
    }
  }
  componentWillUnmount() {
    window.removeEventListener('resize', this.updateDimensions);
  }

  onDeleteResult = id => {
    const confirmValue = confirm('Do you want to remove this Mail Config?'); // eslint-disable-line
    if (confirmValue) {

        //get selected menu
      let selectedMenu = window.localStorage.getItem("selectedMenuGroup");

      //if menu is not set then set default menu(Utm general) from here
      if(!selectedMenu || selectedMenu == '') {
        selectedMenu = 'utmGeneral';
      }

      this.props.deleteMailFunction(id, selectedMenu);
    }
  };

  onUpdateResult = id => {
    const editNode = this.state.data.find(o => o.configID === id);
    this.setState({
      editNode,
      mode: 'edit'
    });
  };

  addEmail = id => {
    const selectedNode = this.state.data.find(o => o.configID === id);

    const { cropCode, configGroup } = selectedNode;
    this.setState({
      mode: 'add',
      editNode: {
        configID: 0,
        cropCode,
        recipients: '',
        configGroup
      }
    });
  };

  filterFetch = () => {
    this.props.filterAdd(this.state.localFilter);
  };
  filterClear = () => {
    this.props.filterClear();
    this.setState({ localFilter: [] });
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
  localFilterAdd = (name, value) => {
    const { localFilter } = this.state;
    const obj = {
      name,
      value,
      expression: "contains",
      operator: "and",
      dataType: "NVARCHAR(255)"
    };

    const check = localFilter.find(d => d.name === obj.name);
    let newFilter = "";
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

  computeData = () => {
    const { data } = this.state;
    const { filter: filterLength } = this.props;

    let filterData2 = [];
    if (filterLength.length > 0) {
      const filter = {};
      filterLength.map(i => {
        const { name, value } = i;
        Object.assign(filter, { [name]: value });
        return null;
      });

      filterData2 = data.filter(item => {
        /* eslint-disable */
        for (const key in filter) {
          const itemLower = item[key]
            ? item[key].toString().toLowerCase()
            : '';
          const filterLower = filter[key]
            ? filter[key].toString().toLowerCase()
            : '';
          const wildFilter = !itemLower.includes(filterLower);
          if (item[key] === undefined || wildFilter) return false;
        }
        /* eslint-enable */

        return true;
      });
    } else {
      filterData2 = data;
    }

    return filterData2;
  };

  pageClick = pg => {
    //get selected menu
    let selectedMenu = window.localStorage.getItem("selectedMenuGroup");

    //if menu is not set then set default menu(Utm general) from here
    if(!selectedMenu || selectedMenu == '') {
      selectedMenu = 'utmGeneral';
      window.localStorage.setItem("selectedMenuGroup", selectedMenu);
    }

    // fetch date in new page
    this.props.fetchMail(pg, this.state.pagesize, selectedMenu);

    // Highlight current page
    this.setState({ pagenumber: pg });
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

  formUI = () => {
    const { mode, editNode } = this.state;
    if (mode === '') return null;
    // const { crops } = this.props;

    // data , crops
    if (mode === 'add') {
      return (
        <Result
          close={this.mode}
          mode={mode}
          editData={editNode}
          onAppend={this.props.addMailFunc}
          crops={this.props.crops}
          breedingStation={this.state.breedingStation}
        />
      );
    }
    return (
      <Result
        close={this.mode}
        mode={mode}
        editData={editNode}
        onAppend={this.props.editMailFunc}
        crops={this.props.crops}
        breedingStation={this.state.breedingStation}
      />
    );
  };

  render() {
    const {
      tblHeight,
      tblWidth,
      data,
      total,
      pagesize,
      pagenumber
    } = this.state;
    const calcTblHeight = tblHeight - 125;

    const columns = [
      'configGroup',
      'cropCode',
      'brStationCode',
      'recipients',
      'Action'
    ];
    const columnsMapping = {
      configGroup: { name: 'Group', filter: true, fixed: false },
      cropCode: { name: 'Crop Code', filter: true, fixed: false },
      brStationCode: { name: 'Br.Station', filter: true, fixed: false },
      recipients: { name: 'Recipients', filter: true, fixed: true },
      Action: { name: 'Action', filter: false, fixed: false }
    };
    const columnsWidth = {
      configGroup: 300,
      cropCode: 110,
      brStationCode: 110,
      recipients: 300,
      Action: 100
    };

    return (
      <div className="traitContainer">
        <section className="page-action">
          <div className="left"> {this.filterClearUI()} </div>
          <div className="right" />
        </section>
        <div className="container">
          <PHTable
            sideMenu={this.props.sideMenu}
            filter={[]}
            tblWidth={tblWidth}
            tblHeight={calcTblHeight}
            columns={columns}
            data={this.computeData()}
            pagenumber={pagenumber}
            pagesize={pagesize}
            total={total}
            pageChange={this.pageClick}
            columnsMapping={columnsMapping}
            columnsWidth={columnsWidth}
            filterFetch={this.filterFetch}
            filterClear={this.filterClear}
            filterAdd={this.props.filterAdd}
            localFilterAdd={this.localFilterAdd}
            localFilter={this.state.localFilter}
            actions={{
              name: 'mail',
              add: this.addEmail,
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

MailComponent.defaultProps = {
  email: [],
  crops: [],
  breedingStation: [],
  filter: [],
  selectedMenu: ''
};
MailComponent.propTypes = {
  breedingStation: PropTypes.array, // eslint-disable-line
  fetchBreeding: PropTypes.func.isRequired,
  sideMenu: PropTypes.bool.isRequired,
  fetchMail: PropTypes.func.isRequired,
  deleteMailFunction: PropTypes.func.isRequired,
  addMailFunc: PropTypes.func.isRequired,
  editMailFunc: PropTypes.func.isRequired,
  crops: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  email: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  total: PropTypes.number.isRequired,
  pagenumber: PropTypes.number.isRequired,
  pagesize: PropTypes.number.isRequired,
  refresh: PropTypes.bool.isRequired,
  filter: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  filterClear: PropTypes.func.isRequired,
  filterAdd: PropTypes.func.isRequired,
};

const mapState = state => ({
  crops: state.user.crops
});
export default connect(
  mapState,
  null
)(MailComponent);
