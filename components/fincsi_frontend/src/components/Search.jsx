import axios from "../axios";
import { useState, useEffect } from 'react'
import Recipe from "./Recipe"
import "./Recipe"

export default function Search() {
    const [recipeList, setRecipeList] = useState([]);
    const [selectedRecipe, setSelectedRecipe] = useState(null);
    const [searchTerm, setSearchTerm] = useState([]);

    const handleRecipeSelect = (recipe) => {
        setSelectedRecipe(recipe);
    }

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            const response = await axios.get(
                "/api/falatok/recipes/?search=" + searchTerm).then(
                    function (response) {
                        setRecipeList(response.data.results);
                        console.log(response.data.results);
                    }
                );
            console.log(response);
        } catch (error) {
            console.log(error);
        }
    };

    console.log(selectedRecipe);
    if (!selectedRecipe) {
        return (
            <div className="recipeList">
                <h1>Keresés</h1>
                <form onSubmit={handleSubmit} className="searchForm">
                    <label htmlFor="search">Találja meg kedvenc receptjeit :)</label><br></br>
                    <input
                        type="text"
                        id="search"
                        onChange={(e) => setSearchTerm(e.target.value)}
                        placeholder="..."
                        name="s"
                        className="searchInput"
                    />
                    <button type="submit" className="searchButton">Keresés</button>
                </form>

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
        );
    } else {
        return <Recipe recipe={selectedRecipe} />;
    }
}