import { createBrowserRouter } from "react-router-dom"
import Layout from "../components/layout/Layout"
import PageNotFound from "../Pages/Error/NotFoundPage"
import { WalletProvider } from "../context/userContext"
import Onboardingscreen from "../pages/Onboarding"
import HomeScreen from "../pages/HomeScreen"
import PrivateRoute from "./PrivateRoute"

export const Mainroute = createBrowserRouter([

  {
    element: (
      <WalletProvider>
        <Layout />
      </WalletProvider>
    ),
    children: [
      {
        path: "/",
        element: <Onboardingscreen />
      },
      {
        path: "/homescreen",
        element: <PrivateRoute element={<HomeScreen />} />
      },
    ],
  },
  {
    path: "*",
    element: <PageNotFound />
  }
])
