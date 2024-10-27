import { createContext, useState } from "react";
import { AppConfig, UserSession, showConnect } from '@stacks/connect';
const UserContext = createContext();

// eslint-disable-next-line react/prop-types
const WalletProvider = ({ children }) => {
  const [isLoading, setIsLoading] = useState(false);
  const [userDetails, setUserDetails] = useState()
  const [userWalletAddress, setUserWalletAddress] = useState()
  const [loadingMessage, setLoadingMessage] = useState("")
  const [userData, setUserData] = useState({});
  const appConfig = new AppConfig(['store_write', 'publish_data']);
  const userSession = new UserSession({ appConfig });

  const userAuth = async () => {
    setIsLoading(true)
    setLoadingMessage("Connecting Wallet..")
    return new Promise((resolve) => {
      showConnect({
        appDetails: {
          name: 'Clariplay',
          icon: `../assets/clari.svg`,
        },
        redirectTo: "/user/home",
        onFinish: () => {
          setIsLoading(true)
          const userData = userSession.loadUserData();
          if (userData) {
            setLoadingMessage("Wallet connected sucessfully")
            localStorage.setItem('danielmainnetStxAddress', userData.profile.stxAddress.mainnet)
            localStorage.setItem('danieltestnetStxAddress', userData.profile.stxAddress.testnet);
            console.log('User data:', userData);
            resolve(userData);
            setUserDetails(userData);
          }
        },
        userSession,
      })
    })
  }

  const getWalletAddress = () => {
    const details = userDetails
    console.log(details);

    if (details) {
      localStorage.setItem('mainnetStxAddress', details.profile.stxAddress.mainnet);
      localStorage.setItem('testnetStxAddress', details.profile.stxAddress.testnet);
      const stxWallet = localStorage.getItem("mainnetStxAddress")
      console.log("mainnet stxwallet is:", stxWallet)
      setUserWalletAddress(stxWallet)
    } else {
      console.error("No STX Address found in user details.");
    }
  }

  const value = {
    userAuth,
    isLoading,
    setIsLoading,
    setLoadingMessage,
    loadingMessage,
    userSession,
    userDetails,
    getWalletAddress,
    userWalletAddress,
    setUserData,
    userData,
  }
  return (
    <UserContext.Provider value={value}>
      {children}
    </UserContext.Provider>
  )
}

export { UserContext, WalletProvider }