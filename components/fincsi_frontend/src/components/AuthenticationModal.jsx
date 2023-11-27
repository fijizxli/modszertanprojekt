import React, { useState, useContext } from "react";
import DataContext from "../context";
import closeButton from "../assets/close-button.svg";
import axios from "../axios";
import ErrorMessage from "./ErrorMessage";

function Register() {
  const { setAuthModalType } = useContext(DataContext);
  

  const [username, setUsername] = useState("");
  const [password1, setPassword1] = useState("");
  const [password2, setPassword2] = useState("");
  
  const [errorMessage, setErrorMessage] = useState("");
  const [errorPresent, setErrorPresent] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const response = await axios.post(
        "/api/auth/registration/",
        JSON.stringify({ username, password1, password2 }),
        {
          headers: { "Content-Type": "application/json" },
          withCredentials: true,
        }
      );
      setErrorPresent(false)
      setAuthModalType("Inactive")
      
    } catch (error) {
      const message = Object.values(error.response.data)[0];
      console.log(message);
      setErrorMessage(message);
      setErrorPresent(true)
    }
  };

  return (
    <div className="AuthShadow">
      <div className="AuthContainer">
        <div className="Titlebar">
          <h1>Regisztráció</h1>
          <img
            src={closeButton}
            alt="close-button"
            className="Close"
            onClick={() => setAuthModalType("Inactive")}
          />
        </div>
        {errorPresent ? <ErrorMessage text={errorMessage} /> : null}
        <form onSubmit={handleSubmit}>
          <label htmlFor="username">
            <b>Felhasználónév</b>
          </label>
          <input
            className="AuthInput"
            type="text"
            onChange={(e) => setUsername(e.target.value)}
            placeholder="Felhasználónév"
            id="username"
            values={username}
            required
          />

          {/* <label htmlFor="email">
            <b>E-mail</b>
          </label>
          <input
            className="AuthInput"
            type="text"
            placeholder="E-mail"
            id="email"
            values={email}
          /> */}

          <label htmlFor="password1">
            <b>Jelszó</b>
          </label>
          <input
            className="AuthInput"
            type="password"
            placeholder="Jelszó először"
            id="password1"
            onChange={(e) => setPassword1(e.target.value)}
            values={password1}
            required
          />

          <label htmlFor="password2">
            <b>Jelszó</b>
          </label>
          <input
            className="AuthInput"
            type="password"
            placeholder="Jelszó másodszor"
            id="password2"
            onChange={(e) => setPassword2(e.target.value)}
            values={password2}
            required
          />

          {/* <label>
            <input type="checkbox" checked="unchecked" name="remember" /> Szeretnél bejelentkezni inkább?
          </label> */}

          <button className="AuthSubmit" type="submit">
            Regisztráció
          </button>
        </form>
      </div>
    </div>
  );
}

function Login() {
  const { setAuthModalType, setIsLoggedIn } = useContext(DataContext);

  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [errorMessage, setErrorMessage] = useState("");
  const [errorPresent, setErrorPresent] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const response = await axios.post(
        "/api/auth/login/",
        JSON.stringify({ username, password }),
        {
          headers: { "Content-Type": "application/json" },
          withCredentials: true,
        }
      );
      setErrorPresent(false)
      setIsLoggedIn(true);
      setAuthModalType("Inactive");
    } catch (error) {
      const message = Object.values(error.response.data)[0];
      console.log(message);
      setErrorMessage(message);
      setErrorPresent(true)
    }
  };
  
  return (
    <div className="AuthShadow">
      <div className="AuthContainer">
        <div className="Titlebar">
          <h1>Bejelentkezés</h1>
          <img
            src={closeButton}
            alt="close-button"
            className="Close"
            onClick={() => setAuthModalType("Inactive")}
          />
        </div>
        {errorPresent ? <ErrorMessage text={errorMessage} /> : null}
        <form onSubmit={handleSubmit}>
          <label htmlFor="username">
            <b>Felhasználónév</b>
          </label>
          <input
            className="AuthInput"
            type="text"
            placeholder="Felhasználónév"
            id="username"
            values={username}
            onChange={(e) => setUsername(e.target.value)}
            required
          />
          
          <label htmlFor="password">
            <b>Jelszó</b>
          </label>
          <input
            className="AuthInput"
            type="password"
            placeholder="Jelszó"
            id="password"
            values={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />

          {/*<label>
            <input type="checkbox" checked="checked" name="remember" /> Maradj bejelentkezve
          </label>
          */}
          
          <button className="AuthSubmit" type="submit">
            Bejelentkezés
          </button>
        </form>
      </div>
    </div>
  );
}
  


export default function AuthenticationModal() {
  const { AuthModalType } = useContext(DataContext);

  switch (AuthModalType) {
    case "Register":
      return Register();
    case "Login":
      return Login();
    default:
      return null;
  }
}
