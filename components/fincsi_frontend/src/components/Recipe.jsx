import axios from "../axios";
import { useState, useEffect } from 'react';
import { Link, useParams } from 'react-router-dom';



export default function Recipe () {
    const [recipe, setRecipe] = useState([]);
    //recipe = recipe.recipe

    const {recipeId} = useParams();
    console.log(recipeId);
    //console.log(recipe.recipe.id);
    useEffect(()=>{
    axios.get('/api/falatok/recipes/' + recipeId + "/").then(function (response) {
        setRecipe(response.data);
        console.log(response);
    });
    }, []);

    return <div className="recipe">
        <h1>{recipe.title}</h1>
        <img src={recipe.photo} alt="nincs kep." className="recipeimg"></img>

        <h2>Leírás</h2>
        <p>{recipe.description}</p>

        <h2>Hozzávalók</h2>
        <p>{recipe.ingredients}</p>

        <h2>Utasítások</h2>
        <p>{recipe.directions}</p>

        <p><b>Előkészülési idő: </b>{recipe.preparation_time} </p>
        <p><b>Elkészítési idő: </b>{recipe.cooking_time} </p>

    </div>
}