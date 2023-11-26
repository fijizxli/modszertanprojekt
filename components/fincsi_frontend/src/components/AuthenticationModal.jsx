import React, { useState, useContext } from "react";
import DataContext from "../context";
import closeButton from "../assets/close-button.svg";
import axios from "../axios";

function Register() {
  const {setAuthModalType} = useContext(DataContext);
  
  const [username, setUsername] = useState("");
  const [email, setEmail] = useState("");
  const [password1, setPassword1] = useState("");
  const [password2, setPassword2] = useState("");
  

    const handleSubmit = async(e) => {
        e.preventDefault()
        try {
            const response = await axios.post("/api/auth/registration/",
            JSON.stringify({username, email, password1, password2}),
            {
              headers: {"Content-Type": "application/json"},
              withCredentials: true
            }
            );
        } catch (error) {
            console.log(error)
        }
    }
  
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
            placeholder="Felhasználónév"
            id="username"
            values={username}
            required
          />

          <label htmlFor="email">
            <b>E-mail</b>
          </label>
          <input
            className="AuthInput"
            type="text"
            placeholder="E-mail"
            id="email"
            values={email}
            required
          />

          <label htmlFor="password1">
            <b>Jelszó</b>
          </label>
          <input
            className="AuthInput"
            type="psw"
            placeholder="Jelszó először"
            id="password1"
            values={password1}
            required
          />

          <label htmlFor="password2">
            <b>Jelszó</b>
          </label>
          <input
            className="AuthInput"
            type="psw"
            placeholder="Jelszó másodszor"
            id="password2"
            values={password2}
            required
          />

          <label>
            <input type="checkbox" checked="checked" name="remember" /> Maradj bejelentkezve
          </label>

          <button className="AuthSubmit" type="submit">
            Regisztráció
          </button>
        </form>
      </div>
    </div>
  );
}

const Login = () => <div>Login</div>;

const PasswordReset = () => <div>PasswordReset</div>;

const DeleteAccount = () => <div>DeleteAccount</div>;

export default function AuthenticationModal() {
  const { AuthModalType } = useContext(DataContext);

  switch (AuthModalType) {
    case "Register":
      return Register();
    case "Login":
      return Login();
    case "ResetPassword":
      return PasswordReset();
    case "DeleteAccount":
      return DeleteAccount();
    default:
      return null;
  }
}
