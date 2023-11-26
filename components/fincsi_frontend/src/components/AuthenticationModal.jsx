import React, { useState, useContext } from "react";
import DataContext from "../context";
import closeButton from "../assets/close-button.svg";
import axios from "../axios";

function Register() {
  const { setAuthModalType } = useContext(DataContext);

  const [username, setUsername] = useState("");
  const [email, setEmail] = useState("");
  const [password1, setPassword1] = useState("");
  const [password2, setPassword2] = useState("");

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
      console.log(response);
    } catch (error) {
      console.log(error);
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
  const { setAuthModalType } = useContext(DataContext);

  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");

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
    } catch (error) {
      console.log(error);
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

          <label>
            <input type="checkbox" checked="checked" name="remember" /> Maradj bejelentkezve
          </label>

          <button className="AuthSubmit" type="submit">
            Bejelentkezés
          </button>
        </form>
      </div>
    </div>
  );
}
  

function PasswordReset() {
  const { setAuthModalType } = useContext(DataContext);

  const [email, setEmail] = useState("");

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const response = await axios.post(
        "/api/auth/password/reset/",
        JSON.stringify({ email }),
        {
          headers: { "Content-Type": "application/json" },
          withCredentials: true,
        }
      );
    } catch (error) {
      console.log(error);
    }
  };
  
  return (
    <div className="AuthShadow">
      <div className="AuthContainer">
        <div className="Titlebar">
          <h1>Elfelejtetted a jelszavad?</h1>
          <img
            src={closeButton}
            alt="close-button"
            className="Close"
            onClick={() => setAuthModalType("Inactive")}
          />
        </div>
        <form onSubmit={handleSubmit}>
          <label htmlFor="username">
            <b>E-mail cím:</b>
          </label>
          <input
            className="AuthInput"
            type="text"
            placeholder="E-mail"
            id="email"
            values={email}
            required
          />

          <button className="AuthSubmit" type="submit">
            Jelszó helyreállítása
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
    case "ResetPassword":
      return PasswordReset();
    default:
      return null;
  }
}
