export enum DaysInWeek {
  SUNDAY,
  MONDAY,
  TUESDAY,
  WEDNESDAY,
  THRUSDAY,
  FRIDAY,
  SATURDAY,
}

const WEEK_STARTS_ON_RANGE_ERROR = 'weekStartsOn must be between 0 and 6 inclusively';

// Follow this flag for the changes that is made for testing propose asked by Prakash
const CHANGE_DATE_FROM_TO_THRITY_DAYS_PRIOR_AND_DATE_TO_TO_TODAY_PLUS_SEVEN_FOR_TESTING = false;

function numberToDate(date: Date | number): Date {
  return typeof date === 'number' ? new Date(date) : date;
}

function isInTheRageOfDaysInWeek(day: number): boolean {
  return day >= DaysInWeek.SUNDAY && day <= DaysInWeek.MONDAY;
}

function startOfTheWeek(date: Date | number, weekStartsOn: DaysInWeek): Date {
  if (!isInTheRageOfDaysInWeek(weekStartsOn)) {
    throw new RangeError(WEEK_STARTS_ON_RANGE_ERROR);
  }
  date = numberToDate(date);
  const day: number = date.getDay();
  const diff: number = (day < weekStartsOn ? 7 : 0) + day - weekStartsOn;
  date.setDate(date.getDate() - diff);
  date.setHours(0, 0, 0, 0);
  return CHANGE_DATE_FROM_TO_THRITY_DAYS_PRIOR_AND_DATE_TO_TO_TODAY_PLUS_SEVEN_FOR_TESTING
    ? new Date(new Date().setDate(new Date().getDate() - 30))
    : date;
}

function endOfTheWeek(date: Date | number, weekStartsOn: DaysInWeek): Date {
  if (!isInTheRageOfDaysInWeek(weekStartsOn)) {
    throw new RangeError(WEEK_STARTS_ON_RANGE_ERROR);
  }
  date = numberToDate(date);
  const day: number = date.getDay();
  const diff: number = (day < weekStartsOn ? -7 : 0) + 6 - (day - weekStartsOn);
  date.setDate(date.getDate() + diff);
  date.setHours(23, 59, 59, 999);
  return CHANGE_DATE_FROM_TO_THRITY_DAYS_PRIOR_AND_DATE_TO_TO_TODAY_PLUS_SEVEN_FOR_TESTING
    ? new Date(new Date().setDate(new Date().getDate() + 30))
    : date;
}

function formatDate(date: Date): string {
  const offset: number = date.getTimezoneOffset();
  date = new Date(date.getTime() - offset * 60 * 1000);
  return date.toISOString().split('T')[0];
}

export const dateUtils = {
  startOfTheWeek,
  endOfTheWeek,
  formatDate,
};
