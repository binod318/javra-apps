import React, { Fragment } from "react";
import autoBind from "auto-bind";
import PropTypes, { number } from "prop-types";
import PageLink from "./pageLink";
import TLink from "./tLink";
import "./page.scss";

class Page extends React.Component {
  constructor(props) {
    super(props);
    this.msg = "Are you sure you want to leave this page.";
    this.state = {
      message: props.dirtyMessage || this.msg,
      records: props.records,
      pageSize: props.pageSize,
      pageNumber: props.pageNumber
    };
    autoBind(this);
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.pageSize !== this.props.pageSize) {
      this.setState({ pageSize: nextProps.pageSize });
    }
    if (nextProps.records !== this.props.records) {
      this.setState({ records: nextProps.records });
    }
    if (nextProps.pageNumber !== this.props.pageNumber) {
      this.setState({ pageNumber: nextProps.pageNumber });
    }
  }

  _onclick(page) {
    const obj = {
      testID: this.props.testID,
      testTypeID: this.props.testTypeID,
      filter: this.props.filter,
      pageSize: this.state.pageSize,
      pageNumber: page
    };
    this.props.resetSelect();

    if (this.props.isBlocking) {
      if (!confirm(this.state.message)) return null; // eslint-disable-line
    }
    this.props.pageClicked(page);
    this.props.onPageClick(obj);
    this.props.isBlockingChange(false);
    return null;
  }

  showAll = () => {
    const obj = {
      testID: this.props.testID,
      testTypeID: this.props.testTypeID,
      filter: this.props.filter,
      pageSize: this.state.records,
      pageNumber: 1
    };
    if (this.props.isBlocking) {
      if (!confirm(this.state.message)) return null; // eslint-disable-line
    }
    this.props.pageClicked(1);
    this.props.onPageClick(obj);
    this.props.isBlockingChange(false);
    return null;
  };

  render() {
    const { pageNumber, pageSize, records } = this.state;

    const { filterLength } = this.props;
    if (records === 0 && filterLength === 0) return null;
    const totPages = Math.ceil(records / pageSize);
    const display = 5;
    const space = Math.floor(display / 2);
    const linkPush = [];
    const fadd = display - (totPages - pageNumber);
    const ladd = display - (pageNumber - 1);
    const prevNo = pageNumber - 1;
    const nextNo = pageNumber + 1;
    // if (pageSize === records) return null;

    if (totPages > display) {
      linkPush.push(
        <TLink
          page={prevNo}
          key="prev"
          label="prev"
          click={this._onclick}
          active={prevNo >= 1}
        />
      );
      if (pageNumber === 1) {
        for (let i = 1; i <= display; i += 1) {
          linkPush.push(
            <PageLink
              page={i}
              key={i}
              click={this._onclick}
              active={pageNumber === i}
            />
          );
        }
        linkPush.push(
          <TLink
            page={0}
            key="..."
            label="..."
            click={this._onclick}
            active="blank"
          />
        );
        linkPush.push(
          <PageLink
            page={totPages}
            key={totPages}
            click={this._onclick}
            active={false}
          />
        );
      } else if (pageNumber === totPages) {
        linkPush.push(
          <PageLink page={1} key="first" click={this._onclick} active={false} />
        );
        linkPush.push(
          <TLink
            page={0}
            key="..."
            label="..."
            click={this._onclick}
            active="blank"
          />
        );
        let start = totPages - display;
        if (start === 1) {
          start += 1;
        }
        for (let i = start; i <= totPages; i += 1) {
          linkPush.push(
            <PageLink
              page={i}
              key={i}
              click={this._onclick}
              active={pageNumber === i}
            />
          );
        }
      } else {
        linkPush.push(
          <PageLink page={1} key={1} click={this._onclick} active={false} />
        );
        linkPush.push(
          <TLink
            page={0}
            key="..."
            label="..."
            click={this._onclick}
            active="blank"
          />
        );

        let len = space;
        if (fadd > space) len = fadd;
        for (let i = len; i > 0; i -= 1) {
          const d = pageNumber - i;
          if (d > 1)
            linkPush.push(
              <PageLink page={d} key={d} click={this._onclick} active={false} />
            );
        }
        linkPush.push(
          <PageLink
            page={pageNumber}
            key={pageNumber}
            click={this._onclick}
            active
          />
        );
        let len2 = space;
        if (ladd > space) len2 = ladd;
        for (let i = 1; i <= len2; i += 1) {
          const d = pageNumber + i;
          if (d < totPages)
            linkPush.push(
              <PageLink page={d} key={d} click={this._onclick} active={false} />
            );
        }
        linkPush.push(
          <TLink
            page={0}
            key="...."
            label="..."
            click={this._onclick}
            active="blank"
          />
        );
        linkPush.push(
          <PageLink
            page={totPages}
            key={totPages}
            click={this._onclick}
            active={false}
          />
        );
      }
      linkPush.push(
        <TLink
          page={nextNo}
          key="next"
          label="next"
          click={this._onclick}
          active={nextNo <= totPages}
        />
      );
    } else {
      for (let i = 1; i <= totPages; i += 1) {
        if (pageNumber === i)
          linkPush.push(
            <PageLink
              page={i}
              key={i}
              click={this._onclick}
              active={pageNumber === i}
            />
          );
        else
          linkPush.push(
            <PageLink page={i} key={i} click={this._onclick} active={false} />
          );
      }
    }

    // <div className="grid-navigation trow">
    const btnStyle = {
      right: "15px",
      position: "absolute"
    };
    const showAllBtn =
      (this.props.testTypeID === 8 || this.props.testTypeID === 9 || this.props.testTypeID === 10) ? (
        <button onClick={this.showAll} style={btnStyle}>
          Show all
        </button>
      ) : (
        ""
      );
    return (
      <Fragment>
        <div className="">
          <div className="paginationWrapper">
            <div className="recordCount">
              {this.props.total &&
                Object.keys(this.props.total).length > 0 &&
                `Showing ${this.props.total.total} of total ${
                  this.props.total.grandTotal
                } records`}
            </div>
            {records > pageSize && <ul className="pagination">{linkPush}</ul>}
            {showAllBtn}
          </div>
        </div>
      </Fragment>
    );
  }
}

Page.defaultProps = {
  testTypeID: 0,
  // _fixColumn: null,
  // clearFilter: null,
  testID: null,
  filterLength: null,
  dirtyMessage: "",
  resetSelect: () => {},
  isBlockingChange: () => {}
};
Page.propTypes = {
  testTypeID: PropTypes.number,
  filter: PropTypes.oneOfType([PropTypes.object, PropTypes.array]).isRequired, // eslint-disable-line react/forbid-prop-types
  isBlocking: PropTypes.bool.isRequired,
  isBlockingChange: PropTypes.func,
  onPageClick: PropTypes.func.isRequired,
  pageClicked: PropTypes.func.isRequired,
  // _fixColumn: PropTypes.func,
  // clearFilter: PropTypes.func,
  pageNumber: PropTypes.number.isRequired,
  pageSize: PropTypes.number.isRequired,
  records: PropTypes.number.isRequired,
  filterLength: PropTypes.number,
  testID: PropTypes.number,
  dirtyMessage: PropTypes.string,
  resetSelect: PropTypes.func,
  total: PropTypes.shape({
    total: number,
    grandTotal: number,
    pageNumber: number,
    pageSize: number
  })
};

export default Page;
