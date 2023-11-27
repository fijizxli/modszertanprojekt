import React from 'react'
import fincsiLogo from '../assets/logo-wide-2400x800.png'
import { useContext } from 'react'
import DataContext from '../context'
import { Link } from 'react-router-dom'


export default function Navbar() {
  const {isLoggedIn} = useContext(DataContext);

  const GuestNavbar = () => {
    const {isLoggedIn, setAuthModalType} = useContext(DataContext);
    
    return <div>
      <nav>
        <img src={fincsiLogo} alt='Logo' className='Logo'></img>
        <li><Link to="/search">Keresés</Link></li>
        <li><Link to="/recipes">Felfedezés</Link></li>
        <li><Link to="/addrecipe">Új recept</Link></li>
        <li className='Spacer'>{isLoggedIn}</li>
        <li className='SignIn' onClick={() => setAuthModalType("Login")}>Bejelentkezés</li>
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
