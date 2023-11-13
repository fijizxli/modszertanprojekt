import React, {useContext} from 'react'
import AppContext from './AppContext';
import fincsiLogo from '../assets/logo-wide-2400x800.png'
import {SignupMenu} from './Authentication';

import Footer from './Footer';


export default function Navbar() {
  const {isLoggedIn, toogleAuthMenu, isAuthMenuOpen} = useContext(AppContext);

  
  
  const UserGreeting = () => {
    const {logout} = useContext(AppContext);

    return <div>
            <nav>
              <ul>
                <img src={fincsiLogo} alt='Logo' className='Logo'></img>
                <li>Keresés</li>
                <li>Felfedezés</li>
                <li>Új recept</li>
                <li className='Spacer'>{isLoggedIn}</li>
                <button className='Profile' onClick={logout}>Kijelentkezés</button>

              </ul>
            </nav>
         </div>;
  };
  
  const GuestGreeting = () => {
    const {isLoggedIn, toogleAuthMenu, isAuthMenuOpen} = useContext(AppContext);
    
    return <div>
      <nav>
        <img src={fincsiLogo} alt='Logo' className='Logo'></img>
        <li>Keresés</li>
        <li>Felfedezés</li>
        <li>Új recept</li>
        <li className='Spacer'>{isLoggedIn}</li>
        <li className='SignIn'>Bejelentkezés</li>
        <button className='Profile' onClick={toogleAuthMenu}>Regisztráció</button>
        <p>{isAuthMenuOpen}</p>
        
      </nav>
      {isAuthMenuOpen && <SignupMenu/>}
    </div>;
    
  };
  
  if (isLoggedIn) {
    return <UserGreeting/>;
  } else {
    return <GuestGreeting/>;
  }
  
}
