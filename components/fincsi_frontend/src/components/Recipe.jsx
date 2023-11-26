import axios from "../axios";
import { useState, useEffect } from 'react'


export default function Recipe (recipe) {
    // const [reciperesponse, setRecipereciperesponse] = useState([]);
    recipe = recipe.recipe
    //console.log(recipe.recipe.id);
    // useEffect(()=>{
    // axios.get('/api/falatok/recipes/' + recipe.recipe.id).then(function (response) {
    //     console.log(recipe_id);
    //     setRecipe(response.data);
    // });
    // }, []);

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