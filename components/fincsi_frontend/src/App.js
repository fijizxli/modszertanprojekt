import "./App.css";
import { DataProvider } from "./context";
import Navbar from "./components/Navbar";
import Lorem from "./components/Lorem";
import Footer from "./components/Footer";
import "./components/Navbar";
import AuthenticationModal from "./components/AuthenticationModal";
import Teszt from "./components/Teszt";

/**
 * Navbar // add @media css rules for navbar
 * add hamburger menu
 * main part
 *
 */

function App() {
  return (
    <DataProvider>
      <div className="App">
        <Navbar />
        <AuthenticationModal />
        <Teszt/>
        <h1>Hello World</h1>
        <Lorem />
        <Lorem />
        <Lorem />
        <Lorem />
        <Footer />
      </div>
    </DataProvider>
  );
}

export default App;
