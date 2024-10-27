import { Link } from 'react-router-dom';

const PageNotFound = () => {
  return (
    <div className="">
      <h1 className="">404</h1>
      <h2 className="">Oops! Page Not Found</h2>
      <p className="">
        The page you are looking for might have been removed, had its name changed, or is temporarily unavailable.
      </p>
      <Link to="/" className="">
        Go to Homepage
      </Link>
    </div>
  );
};

export default PageNotFound;