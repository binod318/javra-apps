// actions
export const setPageTitle = title => ({
  type: 'SET_PAGETITLE',
  title
});

export function sidemenuToggle() {
  return {
    type: 'TOGGLE_SIDEMENU'
  };
}
export function sidemenuClose() {
  return {
    type: 'ASSIGN_SIDEMENU',
    status: false
  };
}

export const locationFetch = () => ({
  type: "LAB_LOCATION_FETCH"
});

export const locationAdd = data => ({
  type: "LAB_LOCATION_ADD",
  data
});

