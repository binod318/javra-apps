import { LoadingOutlined } from '@ant-design/icons';
import { SpinIndicator } from 'antd/lib/spin';

export default function loadingIcon(): SpinIndicator {
  return <LoadingOutlined style={{ fontSize: 24 }} spin />;
}
