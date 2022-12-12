import { Modal } from 'antd';
import React, { useState } from 'react';
import { useHistory } from 'react-router-dom';
import backButtonUrl from '../images/back.svg';
import homeButtonUrl from '../images/home.svg';
import offlineIconUrl from '../images/wifi.svg';
import style from './Header.module.less';
import { useGlobalState } from '../contexts';
import { InfoCircleOutlined } from '@ant-design/icons';

const Header: React.FC = () => {
  const history = useHistory();
  const [isConnectionModalVisible, setIsConnectionModalVisible] = useState(false);
  const { state } = useGlobalState();
  const goBack = function goBack() {
    history.goBack();
  };

  const goHome = function goHome() {
    window.location.href = window.HOME_URL;
  };

  function toggleConnectionModal() {
    setIsConnectionModalVisible(!isConnectionModalVisible);
  }

  return (
    <div className={style.header}>
      {state.showHomeButton ? (
        <button onClick={goBack} className={style.backButton} title='Back'>
          <img src={backButtonUrl} />
        </button>
      ) : (
        <div></div>
      )}
      <h2 className={style.appName}> RDT SCORE</h2>
      <div>
        <button className='connection' onClick={toggleConnectionModal}>
          <img src={offlineIconUrl} />
        </button>
        <button
          disabled={!state.isOnline}
          onClick={goHome}
          className={style.homeButton}
          title='Home'
        >
          <img src={homeButtonUrl} />
        </button>
      </div>
      <Modal
        title={
          <span>
            <InfoCircleOutlined style={{ color: 'green', fontSize: 22, marginRight: 10 }} />
            {state.isOnline ? " You've connection!" : ' Into the wilds!'}{' '}
          </span>
        }
        visible={isConnectionModalVisible}
        footer={null}
        onCancel={() => toggleConnectionModal()}
        className='modal'
        width={'90%'}
        style={{ maxWidth: 500 }}
      >
        {state.isOnline ? (
          <div>
            The app is connected to network. All scored contents will be syned instantly. Yay !
          </div>
        ) : (
          <div>
            <p>
              The app is offline available. All scored contents will be be saved locally. So, please
              continue working.
            </p>
            <p>Once the connection becomes avaiable, all contents will be synced.</p>
          </div>
        )}
      </Modal>
    </div>
  );
};

export default Header;
