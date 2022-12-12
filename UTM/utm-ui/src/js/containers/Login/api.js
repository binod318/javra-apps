import axios from 'axios';

function utmLogin() {
  return axios({
    method: 'post',
    url: 'https://onprem.unity.phenome-networks.com/login_do',
    data: {
      username: 'user@enzazaden.com',
      password: 'enzds321'
    }
  });
}
export default utmLogin;
