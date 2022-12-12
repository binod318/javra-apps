import React from 'react';

const RadioBox = name =>
    <div>{name}</div>;

const RadioBox1 = (fileStatus, name, statusCode, change) => {
  const match = fileStatus === statusCode;
  return <div>{name}</div>;
};
export default RadioBox;
