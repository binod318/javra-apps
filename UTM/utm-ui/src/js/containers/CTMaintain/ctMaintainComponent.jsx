import React from 'react';
import PropTypes from 'prop-types';
import { Tab, Tabs, TabList, TabPanel } from 'react-tabs';

import FormCTMaintain from './component/FormCTMaintain';
import Process from './component/Process';
import LabLocation from './component/LabLocation';
import StartMaterial from './component/StartMaterial';
import TypeCT from './component/TypeCT';

class CTMaintainComponent extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      refresh: props.refresh, // eslint-disable-line
      mode: '',
      editNode: {},
      tabIndex: 0
    };
  }

  componentDidMount() {
    if (this.state.tabIndex === 0) this.props.fetchProcess();
    if (this.state.tabIndex === 1) this.props.fetchLabLocation();
    if (this.state.tabIndex === 2) this.props.fetchStartMaterial();
    if (this.state.tabIndex === 3) this.props.fetchTypeCt();
  }

  getTitie = tabIndex => {
    switch (tabIndex) {
      case 0:
        return 'Process';
      case 1:
        return 'LAB Location';
      case 2:
        return 'Start Material';
      case 3:
        return 'Type';
      default:
        return 'no title';
    }
  };

  closeForm = () => {
    this.setState({ mode: '', editNode: {} });
  };

  saveForm = obj => {
    switch (this.state.tabIndex) {
      case 0:
        this.props.postProcess(obj);
        break;
      case 1:
        this.props.postLabLocation(obj);
        break;
      case 2:
        this.props.postStartMaterial(obj);
        break;
      case 3:
        this.props.postTypeCT(obj);
        break;
      default:
    }

    if (this.state.mode !== '') this.closeForm();
  };

  editForm = rowIndes => {
    let obj = {};
    switch (this.state.tabIndex) {
      case 0: {
        const tt = this.props.process[rowIndes];
        obj.id = tt.processID;
        obj.name = tt.processName;
        obj.statusName = tt.statusName;
        break;
      }
      case 1: {
        const tt = this.props.location[rowIndes];
        obj.id = tt.labLocationID;
        obj.name = tt.labLocationName;
        obj.statusName = tt.statusName;
        break;
      }
      case 2: {
        const tt = this.props.startMaterial[rowIndes];
        obj = {
          id: tt.startMaterialID,
          name: tt.startMaterialName,
          statusName: tt.statusName
        };
        break;
      }
      case 3: {
        const tt = this.props.typeCT[rowIndes];
        obj = {
          id: tt.typeID,
          name: tt.typeName,
          statusName: tt.statusName
        };
        break;
      }
      default:
    }

    this.setState({ mode: 'edit', editNode: obj });
  };

  render() {
    const { tabIndex } = this.state;
    const { process, location, startMaterial, typeCT, sideMenu } = this.props;
    const {
      fetchProcess,
      fetchLabLocation,
      fetchStartMaterial,
      fetchTypeCt
    } = this.props;

    const title = this.getTitie(tabIndex);

    return (
      <div>
        <section className="page-action">
          <div className="left" />
          <div className="right">
            <button
              onClick={() => {
                this.setState({ mode: 'add' });
              }}
            >
              Add {title}
            </button>
          </div>
        </section>
        <br />
        <div className="container">
          <Tabs
            defaultIndex={tabIndex}
            onSelect={index => {
              this.setState(() => ({ tabIndex: index }));
              if (index === 0 && process.length === 0) fetchProcess();
              if (index === 1 && location.length === 0) fetchLabLocation();
              if (index === 2 && startMaterial.length === 0)
                fetchStartMaterial();
              if (index === 3 && typeCT.length === 0) fetchTypeCt();
            }}
          >
            <TabList>
              <Tab>Process</Tab>
              <Tab>LAB Locatoin</Tab>
              <Tab>Start Material</Tab>
              <Tab>Type</Tab>
            </TabList>

            <TabPanel>
              <Process
                data={process}
                sideMenu={sideMenu}
                pagesize={0}
                pagenumber={0}
                total={process.length}
                mode={this.state.mode}
                dataChange={this.editForm}
              />
            </TabPanel>
            <TabPanel>
              <LabLocation
                data={location}
                sideMenu={sideMenu}
                pagesize={0}
                pagenumber={0}
                total={location.length}
                mode={this.state.mode}
                dataChange={this.editForm}
              />
            </TabPanel>
            <TabPanel>
              <StartMaterial
                data={startMaterial}
                sideMenu={sideMenu}
                pagesize={0}
                pagenumber={0}
                total={startMaterial.length}
                mode={this.state.mode}
                dataChange={this.editForm}
              />
            </TabPanel>
            <TabPanel>
              <TypeCT
                data={typeCT}
                sideMenu={sideMenu}
                pagesize={0}
                pagenumber={0}
                total={typeCT.length}
                mode={this.state.mode}
                dataChange={this.editForm}
              />
            </TabPanel>
          </Tabs>
        </div>
        {this.state.mode !== '' && (
          <FormCTMaintain
            title={title}
            editNode={this.state.editNode}
            mode={this.state.mode}
            save={this.saveForm}
            close={this.closeForm}
          />
        )}
      </div>
    );
  }
}

CTMaintainComponent.defaultProps = {
  process: [],
  location: [],
  startMaterial: [],
  typeCT: []
};
CTMaintainComponent.propTypes = {
  sideMenu: PropTypes.bool.isRequired,
  fetchProcess: PropTypes.func.isRequired,
  postProcess: PropTypes.func.isRequired,
  process: PropTypes.array, // eslint-disable-line
  fetchLabLocation: PropTypes.func.isRequired,
  postLabLocation: PropTypes.func.isRequired,
  location: PropTypes.array, // eslint-disable-line
  fetchStartMaterial: PropTypes.func.isRequired,
  postStartMaterial: PropTypes.func.isRequired,
  startMaterial: PropTypes.array, // eslint-disable-line
  fetchTypeCt: PropTypes.func.isRequired,
  postTypeCT: PropTypes.func.isRequired,
  typeCT: PropTypes.array // eslint-disable-line
};
export default CTMaintainComponent;
