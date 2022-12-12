import React from "react";
import { Link, Prompt } from "react-router-dom";
import PropTypes from "prop-types";
import PHTable from "../../components/PHTable";
import Notification from "../../components/Notification";
import Wrapper from "../../components/Wrapper";
import Loader from "../../components/Loader";
import LoginForm from "./loginForm";
import Treeview from "./Treeview";
import ReplaceTable from "./replaceTable";
import List from "./components/CheckList";
import { select } from "redux-saga/effects";

class Main extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      status: props.status,

      fileList: props.files,
      fileSelected: props.fileSelected,
      fileStatus: props.fileStatus,

      plantList: props.plant,
      columnList: props.column,
      opasparent: props.opasparent,

      size: props.pageSize,
      page: props.pageNumber,
      filterList: props.filterList,
      sorting: props.sort,

      selectRow: null,
      gid: props.replaceNode || 0,
      stem: props.stem || "",
      checkList: props.selected,
      ctrlIndex: null,
      delay: 250,

      filterKey: "",

      selected: {},

      loading: false,
      importView: props.importView,
      edited: false,
      dirty: false,
      dirtyMsg:
        "Are you sure you want to leave, you will lose your changes if you continue!",
      replaceNode: props.replaceNode,
      flag: props.flag, // eslint-disable-line
      renderChangeMain: props.renderChangeMain, // eslint-disable-line
      isSSo: window.adalConfig.enabled,

      pedigreeView: props.pedigreeView,
      withoutHierarchy: props.withoutHierarchy,

      sendToVarmasFlag: props.sendToVarmasFlag,
      filterName: ""
    };
  }

  componentDidMount() {
    window.addEventListener("beforeunload", this.handleWindowClose);
    window.addEventListener("onbeforeunload", this.handleWindowClose);
    window.addEventListener("resize", this.updateDimensions);
    this.updateDimensions();
    this.props.fetchCountryOrigin();

    if (this.props.fileSelected !== "" && this.props.column.length === 0) {
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
        sort,
        false
      );
      this.props.fetchNewCrop(fileSelected);
      this.createColumn(this.props.column);
    }
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.sendToVarmasStage === "n") {
      this.props.toVarmas();
    }
    if (nextProps.sendToVarmasStage === "end") {
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
      this.props.sendtoVarmasStageFunc("i");
    }
    if (nextProps.pedigreeView !== this.props.pedigreeView) {
      this.setState({ pedigreeView: nextProps.pedigreeView });
    }
    if (nextProps.replaceNode !== this.props.replaceNode) {
      this.setState({ replaceNode: nextProps.replaceNode });
    }
    if (nextProps.stem !== this.props.stem) {
      this.setState({ stem: nextProps.stem });
    }
    if (nextProps.withoutHierarchy !== this.props.withoutHierarchy) {
      this.setState({ withoutHierarchy: nextProps.withoutHierarchy });

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
    if (nextProps.opasparent.length > 0) {
      this.setState({
        opasparent: nextProps.opasparent
      });
    }
    if (nextProps.flag !== this.props.flag) {
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
    if (nextProps.status !== this.props.status) {
      const { product, main, varmas, login, replace } = nextProps.status;
      this.setState({ status: nextProps.status });
      if (
        nextProps.status.import === "success" &&
        nextProps.status.import !== this.state.status.import
      ) {
        this.setState({
          importView: false,
          selectRow: null,
          checkList: []
        });
      }
      if (
        nextProps.status.import === "error" &&
        nextProps.status.from === "import"
      ) {
        this.setState({ importView: true });
      }
      if (
        nextProps.status.replace === "success" &&
        nextProps.status.replace !== this.state.status.replace
      ) {
        this.replaceViewToggle();
      }
      if (
        nextProps.status.import === "procesing" ||
        product === "procesing" ||
        main === "procesing" ||
        varmas === "procesing" ||
        replace === "procesing" ||
        nextProps.status.delete === "procesing" ||
        login === "procesing"
      ) {
        this.setState({ loading: true });
      } else {
        this.setState({ loading: false });
      }
      if (product === "success") {
        this.setState({ dirty: false, edited: false });
      }
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
      this.props.fetchNewCrop(fileSelected);
    }

    if (nextProps.selected !== this.props.selected) {
      this.setState({ checkList: nextProps.selected });

      // TODO check correct gid if
      if (nextProps.selected.length === 1) {
        this.setState({
          gid: nextProps.plant[nextProps.selected[0]].gid || 0
        });
        const stemValue = nextProps.plant[nextProps.selected[0]].stem || "";
        this.props.stemSet(stemValue);
      }
    }

    if (nextProps.files !== this.props.files) {
      this.setState({
        fileList: nextProps.files
      });
    }
    if (nextProps.plant !== this.props.plant) {
      this.setState({ plantList: nextProps.plant });
      this.updateDimensions();
    }

    if (nextProps.column !== this.props.column) {
      this.setState({
        columnList: nextProps.column
      });
      this.createColumn(nextProps.column);
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
    if (nextProps.importView !== this.props.importView) {
      this.setState({
        importView: nextProps.importView
      });
    }
  }
  componentDidUpdate(prevProps) {
    if (prevProps.files.length !== this.props.files.length) {
      this.setState({ fileSelected: this.props.files[0] });
    }
  }
  componentWillUnmount() {
    window.removeEventListener("beforeunload", this.handleWindowClose);
    window.removeEventListener("onbeforeunload", this.handleWindowClose);
    window.removeEventListener("resize", this.updateDimensions);
  }

  onNewCropChange = e => {
    const { selected } = this.state;
    const { productsegment } = this.props;
    const { target } = e;
    const { value } = target; // name
    if (selected.columnKey.toLocaleLowerCase() === "prod.segment") {
      this.props.cropUpdate(
        Object.assign({}, selected, { value, productsegment })
      );
    } else {
      this.props.cropUpdate(Object.assign({}, selected, { value }));
    }

    this.setState({
      edited: true,
      dirty: true
    });
  };

  fetchPhenomToken = () => {
    this.props.fetchPhenomToken(token => {
      this.props.testLogin(token);
    });
  };

  // changed from doubleclick to single click
  handleDoubleClickItem = (index, gid, columnKey, event) => {
    const gids = [];
    const isValidSelect = this.state.checkList.includes(index);
    const { ctrlKey, shiftKey } = event;
    this.prevent = true;

    if (isValidSelect) {
      this.state.plantList
        .filter((v, i) => this.state.checkList.includes(i))
        .map(item => gids.push(item.gid));
    } else {
      gids.push(gid);
    }

    this.setState({
      selected: {
        index,
        gid: gids.join(","),
        columnKey
      }
    });

    if (!(ctrlKey || shiftKey) || !isValidSelect) {
      this.props.selectReset();
    }
  };

  selectBlur = () => {
    this.prevent = false;
    this.setState({
      selected: {
        index: "",
        gid: "",
        columnKey: ""
      }
    });
  };

  selectRow = (rowIndex, shift, ctrl) => {
    const { plantList, ctrlIndex, fileStatus } = this.state; // checkList, selectState,

    // ALL STAGE NO SELECTEION
    if (fileStatus === 0) return null;

    let compoConditon = true;
    if (fileStatus === 100) {
      compoConditon = plantList[rowIndex].statusCode === 100;
    }

    if (compoConditon || plantList[rowIndex].replacedLot) {
      if (ctrl) {
        this.setState({
          ctrlIndex: rowIndex
        });
      }
      const { gid, stem } = plantList[rowIndex];
      this.setState({
        selectRow: rowIndex,
        gid
      });
      // stem
      this.props.stemSet(stem);
      this.props.select(rowIndex, plantList, shift, ctrl, ctrlIndex);
      if (shift) {
        this.setState({
          ctrlIndex: null
        });
      }
    }
    return null;
  };
  selectAll = () => {
    const { plantList } = this.state;
    const { selected } = this.props;
    this.props.selectAll(plantList, selected);
  };
  sendTOVarmas = () => {
    const msg = "Do you want to send selected record(s) to Varmas?";
    if (confirm(msg)) {
      this.props.toVarmas();
    }
  };
  deleteRows = () => {
    const { checkList, plantList } = this.state;
    const varietyArray = [];

    let parent = false;
    checkList.map(i => {
      const { transferType, statusCode, varietyID } = plantList[i];
      const tt = transferType.toLocaleLowerCase();
      if (tt === "hyb" || tt === "cms") {
        parent = true;
      }
      if (statusCode === 100) {
        varietyArray.push(varietyID);
        return i;
      }
      return null;
    });

    const message = parent
      ? "Do you want to deleted selected records(s), include parent(s) also?"
      : "Do you want to deleted selected records(s)?";
    const { fileSelected, pageSize, filterList, sort } = this.props;

    if (confirm(message)) {
      this.props.deleteRow(
        varietyArray,
        fileSelected,
        1,
        pageSize,
        filterList,
        sort
      );
    }
  };

  sendToReciprocal = () => {
    const { plantList, selectRow } = this.state;
    const { varietyID } = plantList[selectRow];
    /**
     * TODO :: reciprocal api call
     * Success - refetch table data and notification, with current page and filter
     * Fail - do nothing, show notification
     */
    this.props.recipocal(varietyID);
  };

  createColumn = columns => {
    const columnWidths = {};

    columns.forEach(column => {
      const lbl = column.traitID ? column.traitID : column.columnLabel;
      let calWidth = lbl.length * 12;
      calWidth = calWidth > 100 ? calWidth : 90;
      Object.assign(columnWidths, { [lbl]: calWidth + 40 });
    });
  };
  handleWindowClose = e => {
    if (this.state.edited) {
      e.returnValue = "blocked";
    }
  };
  updateDimensions = () => {
    const _this = this;
    setTimeout(() => {
      const width = window.document.body.offsetWidth;
      const height = window.document.body.offsetHeight;

      let dec = 110 + 45; // + this.props.sub;
      if (this.props.filterList.length > 0) {
        dec += 25;
      }

      _this.setState({
        tblWidth: width - 30,
        tblHeight: height - dec
      });
    }, 100);
  };

  _onColumnResizeEndCallback = (newColumnWidth, columnKey) => {
    this.setState(({ columnWidths }) => ({
      columnWidths: {
        ...columnWidths,
        [columnKey]: newColumnWidth
      }
    }));
  };

  replaceViewToggleClose = () => {
    this.props.pedigreeReplaceNodeResetFunc();
  };

  replaceViewToggle = () => {
    this.props.resetError();
    this.props.pedigreeReplaceNodeResetFunc();
  };

  pedigreeViewShow = () => {
    const { selected, plant, isLoggedIn } = this.props;
    const { isSSo, stem } = this.state;

    if (!isLoggedIn) {
      if (isSSo) {
        this.fetchPhenomToken();
      }
    }

    const { gid } = plant[selected[0]];
    this.props.pedigreeReplaceNodeFunc(gid);
    this.props.pedigreeViewFunc(true);
    this.props.stemSet(stem);
  };

  importViewToggle = () => {
    const { isLoggedIn } = this.props;
    const { isSSo } = this.state;

    if (!isLoggedIn) {
      if (isSSo) {
        this.fetchPhenomToken();
      }
    }
    this.props.importViewFunc(!this.state.importView);
    this.props.resetError();
  };

  saveTreeObjectData = (
    objectType,
    objectID,
    researchGroupID,
    tree,
    folderObjectType,
    researchGroupObjectType
  ) => {
    const { size, withoutHierarchy } = this.state;
    this.props.fetchData(
      objectType,
      objectID,
      researchGroupID,
      size,
      tree,
      folderObjectType,
      researchGroupObjectType,
      withoutHierarchy
    );
  };

  fileSelect = e => {
    const { target } = e;
    const { value } = target; // name
    this.props.selectReset();
    this.props.fileSelect(value);
  };

  filterKeySet = key => {
    this.setState({
      filterKey: key === this.state.filterKey ? "" : key
    });
  };
  filterSort = (key, direction, traitID) => {
    const { fileSelected, page, size, filterList, sorting } = this.state;
    this.setState({
      selectRow: null,
      checkList: []
    });
    this.props.selectReset();

    let changeDirection = direction;
    let newKey = key;
    if (traitID !== null) {
      newKey = traitID;
    }
    if (sorting.name === newKey) {
      changeDirection = direction === "asc" ? "desc" : "asc";
    } else {
      changeDirection = "asc";
    }

    this.props.fetchMain(fileSelected, page, size, filterList, {
      name: newKey,
      direction: changeDirection
    });
  };
  filterAdd = obj => {
    this.setState({
      selectRow: null,
      checkList: []
    });
    this.props.selectReset();
    this.props.filterAdd(obj);
  };
  filterRemove = name => {
    this.setState({ selectRow: null, checkList: [] });
    this.props.selectReset();
    this.props.filterRemove(name);
  };
  filterClear = () => {
    this.setState({ selectRow: null, checkList: [] });
    this.props.selectReset();
    this.props.filterClear();
  };

  changePage = pageNumber => {
    const { fileSelected, size, filterList, sorting } = this.state;
    this.setState({ selectRow: null, checkList: [] });
    this.props.selectReset();
    this.props.fetchMain(fileSelected, pageNumber, size, filterList, sorting);
  };

  changesSave = () => {
    this.setState({ selectRow: null, checkList: [] });
    this.props.selectReset();
    const { plantList } = this.state;
    const selectedSave = plantList.filter(plant => plant.change === true);
    const finalData = [];
    selectedSave.map(data => {
      const { varietyID, newCrop, cntryOfOrigin } = data;
      finalData.push({
        varietyID,
        newCropCode: newCrop,
        prodSegCode: data["prod.Segment"],
        countryOfOrigin: cntryOfOrigin
      });
      return null;
    });
    this.props.saveData(finalData);
  };

  longClickTimer = null;
  prevent = false;

  cancelLongClick() {
    if (this.longClickTimer) {
      clearTimeout(this.longClickTimer);
      this.longClickTimer = null;
    }
  }

  handleRowMouseDown = (rowIndex, shiftK, ctrlK) => {
    const { delay } = this.state;
    this.cancelLongClick();
    this.longClickTimer = setTimeout(() => {
      if (this.prevent === false) {
        this.selectRow(rowIndex, shiftK, ctrlK);
      }
    }, delay);
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
      console.log("not dirty");
      this.setState({
        selectRow: null
      });
      this.props.fetchFileStatus(statusCode);
      this.props.selectReset();
    }
  };

  importViewUI = () => {
    const { importView, isSSo } = this.state;
    const { isLoggedIn } = this.props;
    const treeUI = (
      <Wrapper>
        <Treeview
          close={this.importViewToggle}
          saveTreeObjectData={this.saveTreeObjectData}
          resetError={this.props.resetError}
        />
      </Wrapper>
    );
    const loginFormUI = (
      <Wrapper>
        <LoginForm close={this.importViewToggle} />
      </Wrapper>
    );

    if (!importView) return null;
    if (isLoggedIn) return treeUI;
    return isSSo ? null : loginFormUI;
  };

  pedigreeViewUI = () => {
    const {
      gid,
      stem,
      pedigreeView,
      replaceNode,
      tblWidth,
      tblHeight,
      isSSo
    } = this.state;
    const { isLoggedIn } = this.props;

    const loginFormUI = (
      <Wrapper>
        <LoginForm close={this.pedigreeViewShow} />
      </Wrapper>
    );

    if (!gid) return null;

    const viewUI = (
      <Wrapper>
        <ReplaceTable
          gid={gid}
          stem={stem}
          baseGid={gid}
          mWidth={tblWidth}
          mHeight={tblHeight}
          close={this.replaceViewToggleClose}
          replaceNode={replaceNode}
          stemKey={this.props.stemKey}
          stemSet={this.props.stemSet}
          stemKeySet={this.props.stemKeySet}
        />
      </Wrapper>
    );

    if (!pedigreeView) return null;
    if (isLoggedIn) return viewUI;
    return isSSo ? null : loginFormUI;
  };

  opAsParentFunc = varietyID => {
    this.props.opAsParentChange(varietyID);
  };

  undoReplaceLot = () => {
    const { selectRow, plantList } = this.state;
    const selectedRecord = plantList[selectRow];
    const payload = {
      gid: selectedRecord.gid
    };
    this.props.undoReplaceLot(payload);
  };

  render() {
    const { checkList, dirty, dirtyMsg, edited, withoutHierarchy } = this.state;
    const { plantList, columnList, filterList } = this.state;
    const { fileList, fileSelected, selected, selectRow } = this.state; // radioActive
    const { loading, sorting, fileStatus, opasparent } = this.state;
    const promptCheck = dirty;
    // Condition check for delete button action
    // if selected row have transferType is Hybrid your delete button will be action
    let isDelete = true;
    if (checkList.length > 0) {
      checkList.some(d => {
        if (isDelete === true) {
          if (plantList[d]) {
            const { canDelete } = plantList[d];
            isDelete = !canDelete;
          }
        }
        return null;
      });
    }

    let isHybrid = false;
    if (checkList.length === 1) {
      if (plantList[selectRow] && plantList[selectRow].transferType === "Hyb") {
        isHybrid = true;
      } else {
        isHybrid = false;
      }
    } else isHybrid = false;

    const filterValue = [
      { name: "Imported", statusCode: 100 },
      { name: "ToVarmas", statusCode: 200 },
      { name: "Stopped", statusCode: 300 },
      { name: "All", statusCode: 0 }
    ];

    let sendTOVarmasDisable = true;
    if (fileStatus === 100) {
      checkList.map(c => {
        sendTOVarmasDisable = false;
        if (plantList[c]) {
          const { statusCode, replacedLot } = plantList[c];
          if (statusCode !== 100 || replacedLot !== false) {
            sendTOVarmasDisable = true;
          }
        }
        return null;
      });
    }

    if (fileStatus === 200) {
      if (checkList.length === 1) {
        checkList.map(c => {
          if (plantList[c] && plantList[c].replacedLot) {
            sendTOVarmasDisable = false;
          }
          return null;
        });
      }
    }
    const statusInitialNotSentToVarmas = ["R0", "R1", "R2", "P0", "P1"];
    const selectedRowStatusInitial =
      selectRow !== null && plantList
        ? plantList[selectRow].status.trim().substring(0, 2)
        : "";
    const sentToVarmas =
      statusInitialNotSentToVarmas.indexOf(selectedRowStatusInitial) === -1;
    return (
      <div className="main">
        <Prompt when={promptCheck} message={dirtyMsg} />

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
                title="Save Changes"
                className="wicon"
                disabled={!edited || fileStatus !== 100}
                onClick={this.changesSave}
                id="main_save_btn"
              >
                <i className="icon icon-floppy" />
                <span>Save</span>
              </button>

              <button
                title="Delete Selected"
                className="wicon"
                disabled={isDelete || fileStatus !== 100}
                onClick={this.deleteRows}
                id="main_delete_btn"
              >
                <i className="icon icon-trash" />
                <span>Delete</span>
              </button>

              <button
                title="Import Data"
                className="wicon"
                onClick={this.importViewToggle}
                id="main_import_btn"
              >
                <i className="icon icon-download-1" />
                <span>Import</span>
              </button>

              <button
                title="Replace"
                className="wicon"
                onClick={this.pedigreeViewShow}
                disabled={
                  this.props.selected.length !== 1 ||
                  fileStatus === 100 ||
                  selectRow === null ||
                  sentToVarmas
                }
                id="main_replace_btn"
              >
                <i className="icon icon-updown-circle" />
                <span>Replace</span>
              </button>
              <button
                title="Undo replace"
                className="wicon"
                onClick={this.undoReplaceLot}
                disabled={
                  this.props.selected.length !== 1 ||
                  !(plantList[selectRow].statusCode > 100) ||
                  (plantList && selectRow !== null
                    ? !plantList[selectRow].replacedLot
                    : false)
                }
                id="main_undo_btn"
              >
                <i className="icon icon-undo" />
                <span>Undo Replace</span>
              </button>

              <button
                className="wicon"
                title="To Reciprocal"
                onClick={this.sendToReciprocal}
                disabled={!isHybrid}
                id="main_reciprocal_btn"
              >
                <i className="icon icon-shuffle" />
                <span>Reciprocal</span>
              </button>

              <button
                className="wicon"
                title="To Varmas"
                onClick={this.sendTOVarmas}
                disabled={sendTOVarmasDisable}
                id="main_send_btn"
              >
                <i className="icon icon-paper-plane" />
                <span>Send to Varmas</span>
              </button>
            </div>
          </div>
        </div>

        {columnList.length > 0 ? (
          <PHTable
            name="main"
            sub={40} // selected={fileSelected}
            withoutHierarchy={withoutHierarchy}
            withoutHierarchyChange={this.props.withoutHierarchyChange}
            filterList={filterList}
            fileStatus={fileStatus}
            plantList={plantList}
            columnList={columnList}
            sorting={sorting}
            total={this.props.total}
            page={this.props.pageNumber}
            size={this.props.pageSize}
            filterSort={this.filterSort}
            close
            filterAdd={this.filterAdd}
            filterRemove={this.filterRemove}
            filterClear={this.filterClear}
            changePage={this.changePage}
            handleRowMouseDown={this.handleRowMouseDown}
            selectRow={selectRow}
            selected={selected}
            checkList={checkList}
            handleDoubleClickItem={
              this.handleDoubleClickItem // selectRow === null ? [] :
            }
            onNewCropChange={this.onNewCropChange}
            selectBlur={this.selectBlur}
            tableType="active"
            opAsParentFunc={this.opAsParentFunc}
            opasparent={opasparent}
          />
        ) : (
          <div className="nomatch norow">
            <h3>No Records</h3>
          </div>
        )}

        {this.importViewUI()}
        {this.pedigreeViewUI()}

        {loading && <Loader />}
        <Notification where="main" close={this.props.resetError} />
        <Notification where="replace" close={this.props.resetError} />

        {this.props.sendToVarmasStage === "c" && (
          <List close={this.props.stopSendToVarmas} />
        )}
      </div>
    );
  }
}

Main.defaultProps = {
  replaceNode: "",
  stem: "",
  stemKey: "",

  files: [],
  fileSelected: "",
  opAsParentChange: () => {}
};
Main.propTypes = {
  replaceNode: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  stem: PropTypes.string,
  importView: PropTypes.bool.isRequired,
  importViewFunc: PropTypes.func.isRequired,
  pedigreeView: PropTypes.bool.isRequired,
  withoutHierarchy: PropTypes.bool.isRequired,
  stemSet: PropTypes.func.isRequired,
  stemKey: PropTypes.string,
  stemKeySet: PropTypes.func.isRequired,
  pedigreeReplaceNodeFunc: PropTypes.func.isRequired,
  pedigreeViewFunc: PropTypes.func.isRequired,
  pedigreeReplaceNodeResetFunc: PropTypes.func.isRequired,

  withoutHierarchyChange: PropTypes.func.isRequired,
  opasparent: PropTypes.array.isRequired, // eslint-disable-line
  recipocal: PropTypes.func.isRequired,
  testLogin: PropTypes.func.isRequired,
  files: PropTypes.array, // eslint-disable-line
  fileStatus: PropTypes.number.isRequired,
  plant: PropTypes.array, // eslint-disable-line
  column: PropTypes.array, // eslint-disable-line
  filterList: PropTypes.array, // eslint-disable-line
  pageSize: PropTypes.number.isRequired,
  pageNumber: PropTypes.number.isRequired,
  total: PropTypes.number.isRequired,
  flag: PropTypes.bool.isRequired,
  isLoggedIn: PropTypes.bool.isRequired,
  status: PropTypes.object.isRequired, // eslint-disable-line
  sort: PropTypes.object.isRequired, // eslint-disable-line
  fileSelected: PropTypes.string,
  fetchMain: PropTypes.func.isRequired,
  fetchNewCrop: PropTypes.func.isRequired,
  fetchCountryOrigin: PropTypes.func.isRequired,
  fetchData: PropTypes.func.isRequired,
  selectAll: PropTypes.func.isRequired,
  toVarmas: PropTypes.func.isRequired,
  deleteRow: PropTypes.func.isRequired,
  resetError: PropTypes.func.isRequired,
  select: PropTypes.func.isRequired,
  selectReset: PropTypes.func.isRequired,
  cropUpdate: PropTypes.func.isRequired,
  saveData: PropTypes.func.isRequired,
  fileSelect: PropTypes.func.isRequired,
  filterAdd: PropTypes.func.isRequired,
  filterRemove: PropTypes.func.isRequired,
  filterClear: PropTypes.func.isRequired,
  fetchFileStatus: PropTypes.func.isRequired,
  opAsParentChange: PropTypes.func,
  productsegment: PropTypes.array, // eslint-disable-line
  undoReplaceLot: PropTypes.func.isRequired
};
export default Main;
