import React from 'react'
import footerDecorator from '../assets/footerDecorator.png'

export default function Footer() {
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
