import { createContext, useState } from "react";

const DataContext =  createContext();

export const DataProvider = ({ children }) => {
    
    const [AuthModalType, setAuthModalType] = useState("Inactive")
    const [isLoggedIn, setIsLoggedIn] = useState(false);
    
    
    const [TestText, setTestText] = useState("Még nem működik")


    
    return (
        <DataContext.Provider value={{ TestText, setTestText}}>
        {children}
      </DataContext.Provider>
    )
}

export default DataContext;