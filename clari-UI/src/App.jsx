import { RouterProvider } from 'react-router-dom'
import { Mainroute } from './routes/mainroutes'

function App() {

  return (
    <>
      <RouterProvider router={Mainroute}>

      </RouterProvider>
    </>
  )
}

export default App