import background from '../assets/bg-0.svg'
import { Link, useNavigate } from 'react-router-dom'
import logo from '../assets/clari.svg'
import tiers from '../../utils'
import { useUser } from '../hook/useUser'

const Onboardingscreen = () => {
  const { userAuth, setLoadingMessage, userSession, setIsLoading } = useUser()
  const navigate = useNavigate()

  const handleclick = () => {
    window.location()
  }
  const connectWallet = async () => {
    await userAuth()
    if (userSession && userSession.isUserSignedIn()) {
      setLoadingMessage("Redirecting to homescreen");
      navigate("/homescreen");
      setIsLoading(false);
    } else {
      setLoadingMessage("User session is not valid");
    }
  }
  return (
    <div className="font-bai h-screen bg-blue-200 text-white" style={{ backgroundImage: `url(${background})`, width: "100%" }}>
      <div className='max-w-screen-2xl mx-auto'>
        <div className='w-[99%] h-[70px] flex justify-between mx-auto items-center'>
          <Link className='flex justify-center items-center' onClick={handleclick}>
            <span>
              <img src={logo} alt="" />
            </span>
            <h2 className='font-bold text-2xl text-white'>Clariplay</h2>
          </Link>
          <div>
            <button className='border border-white rounded-md h-[38px] font-medium text-white bg-white/[.20] px-2 hover:bg-white/[.40]' onClick={connectWallet}>Connect Wallet</button>
          </div>
        </div>
        <div className='h-full flex flex-col justify-start items-start p-5 mt-16'>
          <h1 className='w-full text-6xl font-bold text-center'>
            Tiered Video Access for the Web3 Era
          </h1>
          <p className='text-lg font-medium w-[80%] mt-5 mx-auto text-center'>
            Clariplay leverages blockchain technology to bring you a new era of video streaming with tiered access and advanced features, experience the future of decentralized video streaming with Clariplay. Secure, flexible, and powered by blockchain technology.
          </p>
        </div>
        <div className='h-[350px] w-[93%] mx-auto flex flex-col justify-start items-center mt-16 rounded-2xl bg-white/[.30] p-2 gap-5'>
          <h1 className='text-center text-4xl font-bold mt-5'>How it works</h1>
          <div className='flex flex-row justify-center items-center gap-5'>
            {tiers.map((item, index) => (
              <div key={index} className='w-[400px] p-5 flex gap-3 flex-col bg-black/[.50] mt-10 rounded-lg'>
                <h1 className='text-[#fafafa] text-center rounded-md bg-white/[.20] p-1 w-[60%] text-lg font-bold'>{item.title}</h1>
                <p className='text-[#fafafa] text-base font-semibold bg-white/[.20] p-2 rounded-lg'>{item.description}</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}

export default Onboardingscreen