/**
 * Created by sushanta on 4/12/18.
 */
import React from 'react';
import { connect } from 'react-redux';
import { Treebeard } from 'react-treebeard';
import { contains } from 'ramda';
import PropTypes from 'prop-types';
import { decorators } from 'react-treebeard';

import {
  getResearchGroups,
  getFolders
  // importPhenome
} from '../../../../../actions/phenome';
//import modifiedDecorators from './modifiedDecorators';
import modifiedStyle from './modifiedStyle';
import './index.scss';

class Treeview extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      activeTreeObject: ''
    };
  }
  componentDidMount() {
    if (this.props.data.name === undefined) {
      this.props.getResearchGroups();
    }
  }
  onToggle = (n, toggled) => {
    const { validObjectTypeList } = this.props;
    const node = n;
    if (this.state.cursor) {
      this.setState({
        cursor: {
          ...this.state.cursor,
          active: false
        }
      });
    }
    node.active = true;
    if (node.children) {
      node.toggled = toggled;
    }
    this.setState({ cursor: node });
    if (contains(node.objectType, ['4', '5', '23']) && node.toggled) {
      this.props.getFolders(node.id, node.path);
    }

    if (validObjectTypeList.indexOf( node.objectType) > -1) {
      this.folderID = {
        name: '',
        tree: null,
        folderObjectType: null,
        researchGroupObjectType: null
      };
      const { objectType, id, researchGroupID } = node;
      const { data } = this.props;
      const { children } = data;
      this.findLevelID(children, 0, id);

      const { tree, folderObjectType, researchGroupObjectType } = this.folderID;

      const cropID = tree;

      this.props.saveTreeObjectData(
        objectType,
        id,
        researchGroupID,

        cropID,
        folderObjectType,
        researchGroupObjectType
      );
      this.found = false;

      this.setState({ activeTreeObject : node.id})
    }
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
    const lvl = level + 1;
    for (let i = 0; i < data.length; i += 1) {
      if (this.found) break;
      const { id, children, name, objectType } = data[i];

      if (
        lvl === this.levelGroupObject &&
        this.levelGroupObjectFound === false
      ) {
          Object.assign(this.folderID, {
            researchGroupObjectType: '' // objectType
        });
      }
      if (lvl === this.levelCheck && this.found === false) {
        Object.assign(this.folderID, {
          name,
          tree: id,
          folderObjectType: objectType
        });
      }
      if (source == id) { // eslint-disable-line
        this.found = true;
        this.levelGroupObjectFound = true;
      }
      if (children) {
        if (children.length > 0) {
          this.findLevelID(children, lvl, source);
        }
      }
    }
  };

  render() {
    const { data, validObjectTypeList } = this.props;
    if (!data.name) {
      return null;
    }
    return (
      <div className="phenome-treeview">
        <Treebeard
          style={modifiedStyle}
          data={this.props.data}
          onToggle={this.onToggle}
          //decorators={modifiedDecorators}
          decorators={
            {
              ...decorators,
              Header: obj => {
                const imgBaseUrl = `${services.PHENOME_BASE_URL}/static/images/icons/`; // eslint-disable-line
                // services.PHENOME_BASE_URL + '/static/images/icons/';
                const { node, style } = obj;                
                const displayColor = (validObjectTypeList.indexOf( node.objectType) > -1 ) && this.state.activeTreeObject === node.id;

                return (
                  <div
                    style={{
                      ...style.base,
                      marginLeft: node.children === null ? '19px' : 0
                    }}
                  >
                    <div style={style.title}>
                      <span>
                        <img
                          alt="img icon"
                          style={{ margin: '0 3px -3px 0' }}
                          src={`${imgBaseUrl}${node.img}`}
                        />
                      </span>
                      <span style={{backgroundColor: displayColor ? '#ceefff' : ''}}>{node.name}</span>
                    </div>
                  </div>
                );
              }
            }
          }
        />
      </div>
    );
  }
}

Treeview.defaultProps = {
  data: {}
};
Treeview.propTypes = {
  getResearchGroups: PropTypes.func.isRequired,
  getFolders: PropTypes.func.isRequired,
  saveTreeObjectData: PropTypes.func.isRequired,
  data: PropTypes.object,
  validObjectTypeList: PropTypes.array
};

const mapStateToProps = state => ({
  isLoggedIn: state.phenome.isLoggedIn,
  data: state.phenome.treeData
});
const mapDispatchToProps = {
  getResearchGroups,
  getFolders
};

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(Treeview);
