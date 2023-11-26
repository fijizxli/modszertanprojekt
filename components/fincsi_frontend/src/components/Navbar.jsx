import React from 'react'
import fincsiLogo from '../assets/logo-wide-2400x800.png'
import { useContext } from 'react'
import DataContext from '../context'


export default function Navbar() {
  const {isLoggedIn} = useContext(DataContext);

  const GuestNavbar = () => {
    const {isLoggedIn, setAuthModalType} = useContext(DataContext);
    
    return <div>
      <nav>
        <img src={fincsiLogo} alt='Logo' className='Logo'></img>
        <li>Keresés</li>
        <li>Felfedezés</li>
        <li>Új recept</li>
        <li className='Spacer'>{isLoggedIn}</li>
        <li className='SignIn'>Bejelentkezés</li>
        <button className='Profile' onClick={() => setAuthModalType("Register")}>Regisztráció</button>
      </nav>
    </div>;
  }
  
  const UserNavbar = () => {
    <>I am usernavbar</>
  }
  
  
  return GuestNavbar();
  
  /*  return isLoggedIn ? <UserNavbar /> : <GuestNavbar />;*/
  
  /*if (isLoggedIn) {
    return GuestGreeting;
  } else {
    return GuestGreeting;
  }*/
  
}
