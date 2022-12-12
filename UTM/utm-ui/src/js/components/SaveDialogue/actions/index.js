const SAVE_CONFIGNAME = 'SAVE_CONFIGNAME';

export const saveConfigName = (testID, name) => ({
  type: SAVE_CONFIGNAME,
  testID,
  name
});