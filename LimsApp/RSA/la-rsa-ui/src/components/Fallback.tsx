import { ReactElement } from 'react';

export default function Fallback(): ReactElement {
  return (
    <div className='flash-paint'>
      <h1>
        <img src='/rdt-logo.svg' width='110' />
      </h1>
      <h2>loading...</h2>
    </div>
  );
}
