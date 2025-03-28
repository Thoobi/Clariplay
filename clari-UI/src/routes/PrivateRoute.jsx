import { useUser } from '../hook/useUser'

// eslint-disable-next-line react/prop-types
const PrivateRoute = ({ element }) => {
  const { userAuth, userSession } = useUser();

  return (userAuth && userSession && userSession?.isUserSignedIn() ? element : userSession.signUserOut("/"));
}

export default PrivateRoute;