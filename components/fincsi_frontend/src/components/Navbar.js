import React from 'react'
import fincsiLogo from '../assets/logo-1024x1115.png'

export default function Navbar() {
  return (
    <div>
        <nav>
              <img src={fincsiLogo} alt='Logo' className='Logo'></img>
              <li>Keresés</li>
              <li>Felfedezés</li>
              <li>Új recept</li>
              <li className='Spacer'></li>
              <li className='Profile'>Sign out</li>
      </nav>
    </div> )
}
