import React, { useContext } from "react";
import DataContext from "../context";
import closeButton from "../assets/close-button.svg";

function Register() {
  const { toogleAuthMenu } = useContext(AppContext);

    const HandleSubmit = async(e) => {
        e.preventDefault()
        try {
            const response = await axios.post("/api/auth/registration/",
            JSON.stringify({username, email, password1, password2}),
            {
              headers: {'Context-Type': 'application/json'},
              withCredentials: true
            }
            )
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
            onClick={toogleAuthMenu}
          />
        </div>
        <form>
          <label htmlFor="username">
            <b>Felhasználónév</b>
          </label>
          <input
            className="AuthInput"
            type="text"
            placeholder="Felhasználónév"
            id="uname"
            required
          />

          <label htmlFor="email">
            <b>E-mail</b>
          </label>
          <input
            className="AuthInput"
            type="text"
            placeholder="E-mail"
            id="uname"
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
            required
          />

          <label>
            <input type="checkbox" checked="checked" name="remember" /> Maradjbejelentkezve
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
      return Register;
    case "Login":
      return Login;
    case "ResetPassword":
      return PasswordReset;
    case "DeleteAccount":
      return DeleteAccount;
    default:
      return null;
  }
}
