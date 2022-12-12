import React from 'react';
import { connect } from 'react-redux';
import { Treebeard } from 'react-treebeard';
import { contains } from 'ramda';
import { getResearchGroups, getFolders, importPhenome } from '../action';
import modifiedDecorators from './modifiedDecorators';
import modifiedStyle from './modifiedStyle';

class Treeview extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      cropID: '',
      objectType: '',
      objectID: '',
      message: props.message
    };
  }
  componentDidMount() {
    if (this.props.data.name === undefined) {
      this.props.getResearchGroups();
    }
  }
  componentWillReceiveProps(nextProps) {
    if (nextProps.message !== this.props.message) {
      this.setState({ cropID: '', message: nextProps.message });
    }
  }
  onToggle = (node, toggled) => {
    if (this.state.cursor){
      this.state.cursor.active = false;
    }
    node.active = true;
    const checkObjectTypeForImport = ['6'];
    if (this.state.cursor) {
      this.setState({
        cursor: {
          ...this.state.cursor,
          active: false
        }
      });
    }
    if (node.children) {
      node.toggled = toggled;
    }

    this.setState({ cursor: node });
    if (contains(node.objectType, ['4', '5', '23']) && node.toggled) {
      this.props.getFolders(node.id, node.path);
    }
    if (contains(node.objectType, checkObjectTypeForImport)) {
     
      const { name, objectType, id, researchGroupID } = node;
      if (name.toLowerCase() === 'to varmas') {
        this.found = false;
        this.folderID = { name: '', id: null, researchGroupObjectType: null };
        this.setState({
          cropID: researchGroupID,
          objectType,
          objectID: id
        });
      } else {
        this.setState({
          cropID: '',
          objectType: '',
          objectID: ''
        });
      }
    }

    if (node.objectType !== '6') {
      this.setState({
        cropID: '',
        objectType: '',
        objectID: ''
      });
    }
  };

  validation = () => {
    return this.state.cropID === '';
  };

  found = false;
  levelGroupObjectFound = false;
  folderID = {
    name: '',
    tree: null,
    folderObjectType: null,
    researchGroupObjectType: null
  };
  levelGroupObject = 1; // researchGroupObjectType
  levelCheck = 3; // tree
  findLevelID = (data, level, source) => {
    level++;
    for (let i = 0; i < data.length; i += 1) {
      if (this.found) break;
      const { id, children, name, objectType } = data[i];

      if (
        level === this.levelGroupObject &&
        this.levelGroupObjectFound === false
      ) {
        Object.assign(this.folderID, {
          researchGroupObjectType: objectType
        });
      }
      if (level === this.levelCheck && this.found === false) {
        Object.assign(this.folderID, {
          name,
          tree: id,
          folderObjectType: objectType
        });
      }
      if (source == id) {
        this.found = true;
        this.levelGroupObjectFound = true;
      }
      if (children) {
        if (children.length > 0) {
          this.findLevelID(children, level, source);
        }
      }
    }
  };

  import = () => {
    const { cropID, objectID, objectType } = this.state;
    const { data } = this.props;
    const { children } = data;

    this.findLevelID(children, 0, objectID);
    const { tree, folderObjectType, researchGroupObjectType } = this.folderID;

    this.props.saveTreeObjectData(
      objectType,
      objectID,
      cropID,
      tree,
      folderObjectType,
      researchGroupObjectType
    );
  };

  render() {
    const { data } = this.props;
    const { message } = this.state;
    if (!data.name) {
      return null;
    }
    return (
      <div className="formWrap formImport">
        <div className="formTitle">
          Import from List
          {this.state.cropID !== "" && <span> - Selected</span>}
        </div>
        <div className="formBody">
          {message !== '' && (
            <p className="formErrorP">{message}</p>
          )}

          <div className="treeWrap">
            <Treebeard
              style={modifiedStyle}
              data={this.props.data}
              onToggle={this.onToggle}
              decorators={modifiedDecorators}
            />
          </div>
        </div>
        <div className="formAction">
          <button onClick={this.props.close} id="form_close_btn">Close</button>
          <button
            disabled={this.validation()}
            onClick={this.import}
            id="form_import_btn"
          >
            Import
          </button>
        </div>
      </div>
    );
  }
}

const mapStateToProps = state => ({
  isLoggedIn: state.phenome.isLoggedIn,
  message: state.status.message,
  data: state.phenome.treeData
});
const mapDispatchToProps = {
  getResearchGroups,
  getFolders
};

export default connect(mapStateToProps, mapDispatchToProps)(Treeview);
