import { createContext, useState } from "react";

const DataContext =  createContext();


export const DataProvider = ({ children }) => {
    
    const [TestText, SetTestText] = useState("Még nem működik")
    
    return (
        <DataContext.Provider value={{ TestText, SetTestText}}>
        {children}
      </DataContext.Provider>
    )
}

export default DataContext;