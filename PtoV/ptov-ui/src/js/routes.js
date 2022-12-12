import Main from "./containers/main";
import Convert from "./containers/convert";
import Relation from "./containers/relation";
import Attribute from "./containers/result";
import Mail from "./containers/mail";

const routes = [
  {
    name: "Home",
    path: "/",
    exact: true,
    component: Main,
    role: "ptov-user",
    navbar: true
  },
  {
    name: "Conversion",
    path: "/convert",
    exact: true,
    component: Convert,
    role: "ptov-user",
    navbar: true
  },
  {
    name: "Trait Screening",
    path: "/relation",
    exact: true,
    component: Relation,
    role: "ptov-user",
    navbar: true
  },
  {
    name: "Trait Screening Value",
    path: "/result",
    exact: true,
    component: Attribute,
    role: "ptov-user",
    navbar: true
  },
  {
    name: "Mail Config",
    path: "/mail",
    exact: true,
    component: Mail,
    role: "admin",
    navbar: true
  }
];
export default routes;

export const couputeRoute = (role, mainbar) => {
  const ptovRole = role.includes("ptov-user");
  const adminRole = role.includes("admin");

  const accessRoute = [];
  routes.map(x => {
    const { role: rr, navbar } = x;
    if (mainbar === true) {
      if (navbar === false) return null;
    }
    switch (rr) {
      case "ptov-user":
        if (ptovRole) accessRoute.push(x);
        break;
      case "admin":
        if (adminRole) accessRoute.push(x);
        break;
      default:
    }
    return null;
  });
  return accessRoute;
};
