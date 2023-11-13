import { useState } from "react";
import "./App.css";
import AppProvider from "./components/AppProvider";
import Footer from "./components/Footer";
import Lorem from "./components/Lorem";
import "./components/Navbar";
import Navbar from "./components/Navbar";
import Authentication from "./components/Authentication";

function App() {
  const Signup = (uname, email, psw1, psw2) => {
    fetch("http://localhost:8000/api/auth/registration/", {
      method: "POST",
      body: JSON.stringify({
        username: uname,
        email: email,
        password1: psw1,
        password2: psw2,
      }),
      headers: {
        "Content-type": "application/json; charset=UTF-8",
      },
    }).then((response) => response)
  };

  return (
    <AppProvider>
      <div className="App">
        <Navbar />
        <h1>Hello World</h1>
        <Lorem />
        <Lorem />
        <Lorem />
        <Lorem />
        <Footer />
      </div>
    </AppProvider>
  );
}

export default App;
