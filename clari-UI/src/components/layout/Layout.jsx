import { Outlet, useLocation } from "react-router-dom"
import Header from "../static/Header"
import Footer from '../static/Footer'

const Layout = () => {
  const location = useLocation();
  const noHeaderFooterPaths = ["/", "/provider", "/user", "/research"];
  const showHeader = !noHeaderFooterPaths.includes(location.pathname);
  const showFooter = !noHeaderFooterPaths.includes(location.pathname);

  return (
    <div className="w-full">
      {showHeader && <Header />}
      <Outlet />
      {showFooter && <Footer />}
    </div>

  )
}

export default Layout