import { call, takeLatest, put, select } from "redux-saga/effects"; // select
import { loadState } from "../local";

const fileSelect = cropSelected => ({
  type: "FILE_SELECT",
  cropSelected
});

function computeTimeAdd(t) {
  const adding = t / 60000;
  if (adding < 1) {
    return 1;
  }
  return adding;
}