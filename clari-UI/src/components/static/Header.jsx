import { Link } from 'react-router-dom'
import { useState, useEffect } from 'react';
import logo from '../../assets/clari.svg'
import { useUser } from '../../hook/useUser';
import { FaUserNinja } from "react-icons/fa";
import { GoChevronDown, GoCopy } from "react-icons/go";

const Header = () => {
  const { userSession, getWalletAddress, userWalletAddress } = useUser();
  const [wallet, setWallet] = useState("");
  const [copy, setCopy] = useState(false);
  const stxTWallet = localStorage.getItem('danieltestnetStxAddress');

  useEffect(() => {
    getWalletAddress()
    setWallet(userWalletAddress);
  }, [userWalletAddress, getWalletAddress])

  const handleclick = () => {
    window.location()
  }

  const handleCopy = () => {
    setCopy(true)
    navigator.clipboard.writeText(wallet)
    console.log(wallet);
    setTimeout(() => {
      setCopy(false)
    }, 1000);
  }

  function disconnect() {
    userSession.signUserOut("/");
    localStorage.clear()
  }

  return (
    <div className='font-bai sticky z-10 bg-[#0a0a0a] shadow-md'>
      <div className='w-[90%] h-[70px] flex justify-between mx-auto items-center'>
        <Link className='flex justify-center items-center' onClick={handleclick}>
          <span>
            <img src={logo} alt="" />
          </span>
          <h2 className='font-bold text-2xl text-white'>Clariplay</h2>
        </Link>
        <div className='flex border justify-center items-center border-[#494949] rounded-md gap-5 p-2 h-[40px] text-white'>
          <div className='flex gap-1'>
            <FaUserNinja />
            <GoChevronDown className='cursor-pointer' />
          </div>
          <p>{stxTWallet}</p>
          {copy ? (
            <span className='text-green-500'>
              copied!
            </span>
          ) : (<GoCopy className='cursor-pointer' onClick={handleCopy} />)}
        </div>
        <div>
          <button className='border border-[#494949] rounded-md bg-black/[.20] p-2 hover:bg-white/[.10] font-medium text-white' onClick={disconnect}>Disconnect</button>
        </div>
      </div>
    </div>
  );
};

export default Header;