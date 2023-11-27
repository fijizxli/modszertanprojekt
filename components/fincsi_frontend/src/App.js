import "./App.css";
import { DataProvider } from "./context";
import Navbar from "./components/Navbar";
import Lorem from "./components/Lorem";
import Footer from "./components/Footer";
import "./components/Navbar";
import AuthenticationModal from "./components/AuthenticationModal";
import Teszt from "./components/Teszt";
import Recipe from "./components/Recipe"
import "./components/Recipe"
import Search from "./components/Search"
import "./components/Search"
import RecipeList from "./components/RecipeList"
import "./components/RecipeList"
import {BrowserRouter, Routes, Route} from "react-router-dom";
/**
 * Navbar // add @media css rules for navbar
 * add hamburger menu
 * main part
 *
 */

function App() {
  return (
    //TODO routing
    // <DataProvider>
    // <BrowserRouter>
    //   <Routes>
    //     <Route path = "/" element={<div><Navbar/> <RecipeList/> <Footer/> </div>}/>;
    //   </Routes>
    // </BrowserRouter>
    // </DataProvider>
    <DataProvider>
      <div className="App">
        <Navbar />
        <RecipeList/>
        <AuthenticationModal />
        <Footer />
      </div>
    </DataProvider>
  );
}

export default App;
