import axios from "../axios";
import { useState, useEffect} from 'react'
import Recipe from "./Recipe"
import "./Recipe"
import {Link} from 'react-router-dom';

export default function RecipeList() {
    const [recipeList, setRecipeList] = useState([]);
    const [selectedRecipe, setSelectedRecipe] = useState(null); 
    const handleRecipeSelect = (recipe) => {
        setSelectedRecipe(recipe);
    }
    useEffect(()=>{
    axios.get('/api/falatok/recipes/').then(function (response) {
        setRecipeList(response.data.results);
        console.log(response.data.results);
        });
    }, []);

  
    return (
            <div className="recipeList">
            <h1>Felfedezés</h1>
            <table>
                <th>Recept</th>
                <th></th>
                <th>Elkészítési idő</th>
                {recipeList?.map((recipe) => (
                <tr key={recipe.id}>
                
                <td><Link to={`/recipes/${recipe.id}`}>{recipe.title}</Link></td>
                <td><Link to={`/recipes/${recipe.id}`}><img src={recipe.photo} alt="nincs kep"></img></Link></td>
                <td><Link to={`/recipes/${recipe.id}`}>{recipe.cooking_time}</Link></td>
                
                </tr>
                ))}
            </table>
        </div>
        );
    }