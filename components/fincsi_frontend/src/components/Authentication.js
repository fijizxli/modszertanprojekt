import React, { useContext } from 'react';
import AppContext from './AppContext';
import closeButton from '../assets/close-button.svg'

export function SignupMenu() {
  const {isLoggedIn, toogleAuthMenu, isAuthMenuOpen} = useContext(AppContext);

  
  return <div className='AuthShadow' >
    <div className="AuthContainer">
    <div className='Titlebar'>
    <h1 >Regisztráció</h1> 
    <img src={closeButton} alt='close-button' className='Close' onClick={toogleAuthMenu}/>
    </div>
    <form>
    <label htmlFor="uname"><b>Felhasználónév</b></label>
    <input className='AuthInput' type="text" placeholder="Felhasználónév" name="uname"  required />
    
    <label htmlFor="email"><b>E-mail</b></label>
    <input className='AuthInput' type="text" placeholder="E-mail" name="uname" required />

    <label htmlFor="psw"><b>Jelszó</b></label>
    <input className='AuthInput' type="password" placeholder="Jelszó először" name="psw" required />
    
    <label htmlFor="psw"><b>Jelszó</b></label>
    <input className='AuthInput' type="password" placeholder="Jelszó másodszor" name="psw" required />

    <label><input type="checkbox" checked="checked" name="remember" /> Maradj bejelentkezve</label>
    
    <button className='AuthSubmit' type="submit">Regisztráció</button>
    
    </form>
    
</div>
  </div>
  ;
}

export const loginMenu = () => (
  <div className="container">
    <label htmlFor="uname"><b>Username</b></label>
    <input type="text" placeholder="Enter Username" name="uname" required />

    <label htmlFor="psw"><b>Password</b></label>
    <input type="password" placeholder="Enter Password" name="psw" required />

    <button type="submit">Login</button>
    <label>
      <input type="checkbox" checked="checked" name="remember" /> Remember me
    </label>
  </div>
);


export const passwordResetMenu = () => <div>Login component</div>;
