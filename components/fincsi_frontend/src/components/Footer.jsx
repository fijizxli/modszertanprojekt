import React from 'react'
import footerDecorator from '../assets/footer-decorator.png'
import { useContext } from 'react'
import DataContext from '../context'
export default function Footer() {
  const {isLoggedIn} = useContext(DataContext)

  return (
    <footer>
        <div>
            <p>Szoftverfejlesztési Módszertanok - Fincsi Falatok</p>
            <p>Repó böngészése: <a href='https://p.p2.kolmogorov.space:64743/ModszProj/project/'>https://p.p2.kolmogorov.space:64743/ModszProj/project/</a></p>  
        </div>
        <img src={footerDecorator} alt="Decorator"></img>
    </footer>
  )
}
