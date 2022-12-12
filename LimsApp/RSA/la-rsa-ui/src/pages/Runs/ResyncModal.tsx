import Modal from 'antd/lib/modal/Modal';
import { useEffect, useState } from 'react';
import { useGlobalState } from '../../contexts';
import { LocalRunModel } from '../../models';
import { runsService } from '../../services';

export interface ResyncModalProps {
  run: LocalRunModel;
  toggle: boolean;
  onModalClose: () => void;
}

export const ResyncModal: React.FC<ResyncModalProps> = ({
  run,
  toggle,
  onModalClose,
}: React.PropsWithChildren<ResyncModalProps>) => {
  const [isResyncModalVisible, setIsResyncModalVisible] = useState<boolean>(false);
  const [confirmLoading, setConfirmLoading] = useState<boolean>(false);
  const { state } = useGlobalState();

  useEffect(() => {
    setIsResyncModalVisible(toggle);
  }, [toggle]);

  function toggleResyncModal() {
    setIsResyncModalVisible(!toggle);
    onModalClose();
  }

  async function resyncRun(): Promise<void> {
    try {
      setConfirmLoading(true);
      const synced = await runsService.syncRun(run, true);
      if (!synced) {
        runsService.showSyncErrorNotification([run.id]);
      }
      setConfirmLoading(false);
      setIsResyncModalVisible(!toggle);
      onModalClose();
    } catch {
      runsService.showSyncErrorNotification([run.id]);
    }
  }

  return state.isOnline ? (
    <Modal
      title='Resync this run'
      visible={isResyncModalVisible}
      okText='Confirm'
      onCancel={() => toggleResyncModal()}
      confirmLoading={confirmLoading}
      onOk={resyncRun}
      className='modal'
      width={'90%'}
      style={{ maxWidth: 500 }}
    >
      Your last save was not successful. Are you sure you want to resync this run?
    </Modal>
  ) : (
    <Modal
      title='Resync this run'
      onCancel={() => toggleResyncModal()}
      visible={isResyncModalVisible}
      className='modal'
      width={'90%'}
      style={{ maxWidth: 500 }}
      footer={null}
    >
      Cannot sync data. You are offline !
    </Modal>
  );
};

export default ResyncModal;
