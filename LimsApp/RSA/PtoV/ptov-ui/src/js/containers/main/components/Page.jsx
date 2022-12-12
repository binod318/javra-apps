import React from 'react';

const Page = ({ filterList, filterClear, filterKey, total, page, size, changePage }) => {

  const totalPage = Math.ceil((total/size));
  const display = 4;
  const linkPush = [];
  const prevNo = page === 1 ? 1 : page - 1;
  const nextNo = totalPage === page ? totalPage : page + 1;

  let pg = [];
  if (totalPage > display) {
    for(let i = 1; i <= totalPage; i++) {
      if (i > page - display && i <= page) {
        pg.push(
          <span
            className={page===i ? 'active' : ''}
            key={i}
            onClick={() => changePage(i)}
          >
            {i}
          </span>
        );
      } else if (i > page && i <= page + display - 1 ) {
        pg.push(
          <span
            className={page===i ? 'active' : ''}
            key={i}
            onClick={() => changePage(i)}
          >
            {i}
          </span>
        );
      } else {}
    }
  } else {
    for(let i = 1; i <= totalPage; i++) {
      pg.push(
        <span
          className={page===i ? 'active' : ''}
          key={i}
          onClick={() => changePage(i)}
        >
          {i}
        </span>
      );
    }
  }

  let npg = [];
  if (totalPage > (display)) {

    npg.push(<span key="f" className="jump" onClick={() => changePage(1)}> First </span>);
    npg.push(<span key="p" className="jump" onClick={() => changePage(prevNo)}> &laquo; Prev </span>);
    npg = npg.concat(pg);
    npg.push(<span key="n" className="jump" onClick={() => changePage(nextNo)}> Next &raquo; </span>);
    npg.push(<span key="l" className="jump" onClick={() => changePage(totalPage)}> Last </span>);
  } else {
    if (pg.length>1) {
      npg = npg.concat(pg);
    }
  }
  return (
    <div className="pagination">
      {npg}
    </div>
  );
};
export default Page;
