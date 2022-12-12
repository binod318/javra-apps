import React from "react";
import { Table, Input, Button, Divider, Tag } from "antd";
import uuidv4 from "uuid/v4";

function TblA(props) {
  const { data, columns, total, size, page, height, filter, rowKey } = props;
  const { handleTableChange, rowClassName } = props;
  const computedHeight = height ? height - 200 : 600;

  return (
    <Table
      rowKey={rowKey || uuidv4()}
      dataSource={data}
      columns={columns}
      pagination={{
        total: total,
        pageSize: size,
        current: page,
        showSizeChanger: true,
      }}
      onChange={handleTableChange}
      scroll={{ x: 920, y: computedHeight }}
      size='small'
      filters={filter}
      rowClassName={rowClassName}
    />
  );
}
export default TblA;
