import React from 'react';
import { Table as AntTable } from 'antd';
import { TableProps } from 'antd/lib/table';
import style from './Table.module.less';

/* FIX-ME find a better solution for the any type !
   Problem is that ant design table extends object for
   its prop type and which is not allowed by our
   linting setup we need to find a proper way to 
   TYPE This and remove the skip part !!
*/

/* eslint-disable-next-line  @typescript-eslint/no-explicit-any */
interface BaseTableProps extends TableProps<any> {
  // this is how we can extend functionality of ant table as our use case
  handleResize?: (index: number) => (e: React.SyntheticEvent) => void;
}

export const Table: React.FC<BaseTableProps> = (props: BaseTableProps) => {
  return <AntTable className={style.table} {...props} />;
};

export default Table;
