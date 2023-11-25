import React from 'react'
import fincsiLogo from '../assets/logo-1024x1115.png'
import { useContext } from 'react'
import DataContext from '../context'


export default function Navbar() {
  const {setTestText} = useContext(DataContext);

  const GuestGreeting = () => {
    const {isLoggedIn, setAuthModalType} = useContext(DataContext);
    
    return <div>
      <nav>
        <img src={fincsiLogo} alt='Logo' className='Logo'></img>
        <li>Keresés</li>
        <li>Felfedezés</li>
        <li>Új recept</li>
        <li className='Spacer'>{isLoggedIn}</li>
        <li className='SignIn'>Bejelentkezés</li>
        <button className='Profile' onClick={setAuthModalType("Register")}>Regisztráció</button>
        <p>{isAuthMenuOpen}</p>
      </nav>
    </div>;
  }
  
  
  if (isLoggedIn) {
    return GuestGreeting;
  } else {
    return GuestGreeting;
  }
  
}
