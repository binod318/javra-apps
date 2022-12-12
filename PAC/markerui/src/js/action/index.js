export function sidemenuToggle() {
  return {
    type: "TOGGLE_SIDEMENU",
  };
}
export function sidemenuClose() {
  return {
    type: "ASSIGN_SIDEMENU",
    status: false,
  };
}
