// server.js
import { createServer, Model } from 'miragejs';

const MOCK_RUNS_DATA = {
  runs: [
    {
      id: '8727511',
      workflowCode: 'LT_Bl16_LD',
      workflowName: 'LT_Bl16_LD',
      stepCode: 'BremiaBL22_001',
      stepName: 'Leaf Punch',
      scoreDate: '2021-03-16',
      numberOfPlates: '12',
    },
    {
      id: '8727512',
      workflowCode: 'LT_Bl16_LD',
      workflowName: 'LT_Bl16_LD',
      stepCode: 'BremiaBL22_002',
      stepName: 'Leaf Punch2',
      scoreDate: '2021-03-16',
      numberOfPlates: '12',
    },
    {
      id: '8727513',
      workflowCode: 'LT_Bl16_LD',
      workflowName: 'LT_Bl16_LD',
      stepCode: 'BremiaBL22_003',
      stepName: 'Leaf Punch',
      scoreDate: '2021-03-16',
      numberOfPlates: '12',
    },
    {
      id: '8727514',
      workflowCode: 'LT_Bl16_LD',
      workflowName: 'LT_Bl16_LD',
      stepCode: 'BremiaBL22_004',
      stepName: 'Leaf Punch',
      scoreDate: '2021-03-16',
      numberOfPlates: '12',
    },
    {
      id: '8727515',
      workflowCode: 'LT_Bl16_LD',
      workflowName: 'LT_Bl16_LD',
      stepCode: 'BremiaBL22_005',
      stepName: 'Leaf Punch',
      scoreDate: '2021-03-16',
      numberOfPlates: '12',
    },
  ],
};

const MOCK_RUNS_DETAIL = {
  run: {
    id: '8727511',
    workflowCode: 'LT_Bl16_LD',
    stepcode: 'UB11',
    class: '3a',
    caption: 'FORC',
    columns: [
      {
        columnName: 'RN1',
        caption: 'Bl12',
        dataType: 'LOV',
        LOVs: ['S', '9', '5'],
      },
      {
        columnName: 'RN2',
        caption: 'Bl13'
      },
    ],
    plates: [
      {
        plateID: 'WK11_SP_FORC-1',
        replicateID: '1',
        plateRowCol: 'A2',
        invs: [
          {
            id: '12345',
            score: [
              {
                name: 'RN1',
                val: '9',
                QC: '1',
              },
            ],
          },
          {
            id: '23456',
            score: [
              {
                name: 'RN1',
                val: 'S',
              },
            ],
          },
          {
            id: '23457',
            score: [
            ],
          },
        ],
      },
      {
        plateID: 'WK11_SP_FORC-2',
        replicateID: '2',
        plateRowCol: 'A3',
        invs: [
          {
            id: '5678',
            score: [
              {
                name: 'RN1',
                val: '9',
                QC: '1',
              },
            ],
          },
          {
            id: '91011',
            scores: [
            ],
          },
        ],
      },
    ],
  },
};

export function makeMockServer({ environment = 'test' } = {}) {
  let server = createServer({
    environment,

    models: {
      run: Model,
    },

    seeds(server) {
      server.create('run', MOCK_RUNS_DATA.runs[0]);
      server.create('run', MOCK_RUNS_DATA.runs[1]);
    },

    routes() {
      this.namespace = 'api';
      this.get('/runlist', (schema, request) => MOCK_RUNS_DATA);
      this.get('/rundetail', (schema, request) => {
        const id = request.queryParams.id;
        const stepCode = request.queryParams.stepCode;
        return MOCK_RUNS_DETAIL;
      });
    },
  });

  return server;
}
