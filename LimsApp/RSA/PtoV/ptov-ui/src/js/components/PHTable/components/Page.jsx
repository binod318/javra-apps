import React from 'react';
import PropTypes from 'prop-types';

const Page = ({ total, page, size, changePage }) => {
  const totalPage = Math.ceil(total / size);
  const display = 4;
  const prevNo = page === 1 ? 1 : page - 1;
  const nextNo = totalPage === page ? totalPage : page + 1;

  const pg = [];
  if (totalPage > display) {
    for (let i = 1; i <= totalPage; i += 1) {
      if (i > page - display && i <= page) {
        pg.push(
          <span
            role="button"
            tabIndex={0}
            onKeyPress={() => {}}
            className={page === i ? 'active' : ''}
            key={i}
            onClick={() => changePage(i)}
          >
            {i}
          </span>
        );
      } else if (i > page && i <= page + display - 1) {
        pg.push(
          <span
            role="button"
            tabIndex={0}
            onKeyPress={() => {}}
            className={page === i ? 'active' : ''}
            key={i}
            onClick={() => changePage(i)}
          >
            {i}
          </span>
        );
      }
    }
  } else {
    for (let i = 1; i <= totalPage; i += 1) {
      pg.push(
        <span
          role="button"
          tabIndex={0}
          onKeyPress={() => {}}
          className={page === i ? 'active' : ''}
          key={i}
          onClick={() => changePage(i)}
        >
          {i}
        </span>
      );
    }
  }

  let npg = [];
  if (totalPage > display) {
    npg.push(
      <span
        role="button"
        tabIndex={0}
        onKeyPress={() => {}}
        key="f"
        className="jump"
        onClick={() => changePage(1)}
      >
        First
      </span>
    );
    npg.push(
      <span
        role="button"
        tabIndex={0}
        onKeyPress={() => {}}
        key="p"
        className="jump"
        onClick={() => changePage(prevNo)}
      >
        &laquo; Prev
      </span>
    );
   

    npg = npg.concat(pg);

   
    npg.push(
      <span
        role="button"
        tabIndex={0}
        onKeyPress={() => {}}
        key="n"
        className="jump"
        onClick={() => changePage(nextNo)}
      >
        Next &raquo;
      </span>
    );
    npg.push(
      <span
        role="button"
        tabIndex={0}
        onKeyPress={() => {}}
        key="l"
        className="jump"
        onClick={() => changePage(totalPage)}
      >
        Last
      </span>
    );
  } else {
    npg = pg.length > 1 ? npg.concat(pg) : npg;
  }

  return <div className="pagination">{npg}</div>;
};

Page.propTypes = {
  total: PropTypes.number.isRequired,
  page: PropTypes.number.isRequired,
  size: PropTypes.number.isRequired,
  changePage: PropTypes.func.isRequired
};
export default Page;
