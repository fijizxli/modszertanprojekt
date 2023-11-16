import React from 'react'
import {ReactComponent as FincsiLogo} from '../assets/logo.svg'

export default function Navbar() {
  return (
    <div>
        <nav>
              <div class="logo-container">
                <FincsiLogo/>
              </div>
              <li>Keresés</li>
              <li>Felfedezés</li>
              <li>Új recept</li>
              <li className='Spacer'></li>
              <li className='Profile'>Sign out</li>
       </nav>
    </div> )
}
