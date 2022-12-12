const http = require('http');

it('works with token', async () => {
  return new Promise(resolve => {
    const data = http.get({path: 'https://restcountries.eu/rest/v2/name/aruba?fullText=true'}, response => {
      let data = '';
      response.on('data', _data => (data += _data));
      response.on('end', () => resolve(data));
    });
  });
});