import React from 'react';
import { Layout } from 'antd';
import { ReactNode } from 'react';

import Header from './Header';
import style from './MainLayout.module.less';

const MainLayout: React.FC<{ children: ReactNode }> = ({ children }: { children: ReactNode }) => {
  return (
    <Layout
      className={style.section}
      style={{ background: 'transparent', minHeight: 'calc(100vh - 20px)' }}
    >
      <Header></Header>
      <Layout.Content>{children}</Layout.Content>
    </Layout>
  );
};

export default MainLayout;
