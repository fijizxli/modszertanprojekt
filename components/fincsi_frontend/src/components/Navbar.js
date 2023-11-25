import React from 'react'
import fincsiLogo from '../assets/logo-1024x1115.png'
import { useContext } from 'react'
import DataContext from '../context'


export default function Navbar() {
  const {SetTestText} = useContext(DataContext);
  return (
    <div>
        <nav>
              <img src={fincsiLogo} alt='Logo' className='Logo'></img>
              <li>Keresés</li>
              <li>Felfedezés</li>
              <li>Új recept</li>
              <li className='Spacer'></li>
              <li className='Profile' >Sign out</li>
              <button onClick={() => SetTestText("Műdödik")}>TEST</button>
      </nav>
    </div> )
}
