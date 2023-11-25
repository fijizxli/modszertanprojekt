import './App.css';
import { DataProvider } from './context';
import Footer from './components/Footer';
import Lorem from './components/Lorem';
import './components/Navbar'
import Navbar from './components/Navbar';


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
      <Navbar/>
      <h1>Hello World</h1>
      <Lorem/>
      <Lorem/>
      <Lorem/>
      <Lorem/>
      <Footer/>
    </div>
    </DataProvider>
    
  );
}

export default App;
