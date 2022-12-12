// __mocks__/request.js
const token = {
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJyb2xlIjpbImNyb3Agc3BlY2lhbGlzdCIsImhhbmRsZWxhYmNhcGFjaXR5IiwibWFuYWdlbWFzdGVyZGF0YXV0bSIsIlB0b1YtdXNlciIsInJlcXVlc3R0ZXN0Il0sInVuaXF1ZV9uYW1lIjoiSkFWUkFcXHBzaW5kdXJha2FyIiwiZW56YXV0aC5jcm9wcyI6WyJBTiIsIkNGIiwiRUQiLCJMVCIsIk1FIiwiT04iLCJTTiIsIlRPIl0sImlzcyI6Imh0dHA6Ly9lbnphdXRoIiwiYXVkIjoiaHR0cDovL2VuemF1dGgiLCJleHAiOjE1NDcxMTIyMDEsIm5iZiI6MTU0NzEwNTAwMX0.uHTA6QBiVPwGV8-0rsHvV5bd216x--IRA7SBOyfb7W0",
  "issuedOn": "2019-01-10T07:23:21.0949109Z",
  "expiresIn": "2019-01-10T09:23:21.0949109Z"
}


export default function request(url) {
  return new Promise((resolve, reject) => {
    process.nextTick(() =>
      token.token
        ? resolve(token.token)
        : reject({
            error: 'Token not found.',
          }),
    );
  });
}