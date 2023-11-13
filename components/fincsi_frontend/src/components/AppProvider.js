import React, { useState } from 'react';
import AppContext from './AppContext';

const AppProvider = ({ children }) => {
  const [isLoggedIn, setIsLoggedIn] = useState(false);

  const login = () => {
    setIsLoggedIn(true);
  };

  const logout = () => {
    setIsLoggedIn(false);
  };
  
  const [isAuthMenuOpen, setAuthMenuOpen] = useState(false)
  
  const toogleAuthMenu = () => {
    setAuthMenuOpen(prevState => !prevState);
  }

  const [authMenuType, setAuthMenuType] = useState('inactive')
  
  return (
    <AppContext.Provider value={{isLoggedIn, login, logout, setAuthMenuType, isAuthMenuOpen, toogleAuthMenu}}>
      {children}
    </AppContext.Provider>
  );
};

export default AppProvider;