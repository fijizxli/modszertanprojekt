import axios from "../axios";
import { useState, useEffect} from 'react'
import Recipe from "./Recipe"
import "./Recipe"

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

    console.log(selectedRecipe);
    if (!selectedRecipe){
    return (
            <div className="recipeList">
            <h1>Felfedezés</h1>
            <table>
                <th>Recept</th>
                <th></th>
                <th>Elkészítési idő</th>
                {recipeList?.map((recipe) => (
                <tr key={recipe.id} onClick={() => handleRecipeSelect(recipe)}> 
                <td>{recipe.title}</td>
                <td><img src={recipe.photo} alt="nincs kep"></img></td>
                <td>{recipe.cooking_time}</td>
                </tr>
                ))}
            </table>
            {/* {selectedRecipe && <Recipe recipe={selectedRecipe} />} */}
        </div>
        );}else {
            return <Recipe recipe={selectedRecipe} />;
        }
    }