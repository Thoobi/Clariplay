import { useUser } from "../hook/useUser"

const HomeScreen = () => {
  const { userData } = useUser()
  const data = userData;
  console.log(data);

  return (
    <>
      <div>
        <h1>Homescreen</h1>
      </div>
    </>
  )
}

export default HomeScreen