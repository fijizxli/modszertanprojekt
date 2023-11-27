import axios from "../axios";
import { useState, useEffect } from 'react'

export default function Recipe() {
    const [title, setTitle] = useState([]);
    const [description, setDescription] = useState([]);
    const [ingredients, setIngredients] = useState([]);
    const [directions, setDirections] = useState([]);
    const [photo, setPhoto] = useState([]);
    const [preparation_time, setPreparation_time] = useState([]);
    const [cooking_time, setCooking_time] = useState([]);
    const [guide, setGuide] = useState([]);


    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            const response = await axios.postForm(
                "/api/falatok/recipes/",
                { title:title, 
                    description: description, 
                    ingredients: ingredients, 
                    directions: directions,
                    photo: photo,
                    preparation_time: preparation_time,
                    cooking_time: cooking_time,
                    guide: guide
                },
                {
                    headers: { "Content-Type": "multipart/form-data" },
                    withCredentials: true,
                }
            );
            console.log(response);
        } catch (error) {
            console.log(error);
        }
    };

    return <div className="addrecipeform">
        <h1>Adjon hozzá egy új receptet</h1>
        <form onSubmit={handleSubmit}>
            <label htmlFor="title">Cím</label><br/>
            <input
                className="inputTitle"
                type="text"
                onChange={(e) => setTitle(e.target.value)}
                placeholder="Cím"
                id="title"
                values={title}
                required
            /><br/>
            <label htmlFor="description">Leírás</label><br/>
            <textarea
                className="inputDescription"
                type="textarea"
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Leírás"
                id="description"
                values={description}
                required
            ></textarea><br/>
            <label htmlFor="ingredients">Hozzávalók</label><br/>
            <textarea
                className="inputIngredients"
                type="text"
                onChange={(e) => setIngredients(e.target.value)}
                placeholder="Hozzávalók"
                id="ingredients"
                values={ingredients}
                required
            ></textarea><br/>
            <label htmlFor="directions">Utasítások</label><br/>
            <textarea
                className="inputDirections"
                type="text"
                onChange={(e) => setDirections(e.target.value)}
                placeholder="Utasítások"
                id="directions"
                values={directions}
                required
            ></textarea><br/>
            <label htmlFor="photo">Kép</label><br/>
            <input
                type="file"
                id="photo"
                values={photo}
                onChange={(e) => setPhoto(e.target.files[0])}
                className="photoupload"
            /><br/>

            <label htmlFor="preparation_time">Előkészítési idő</label><br/>
            <input
                type="text"
                id="preparation_time"
                values={preparation_time}
                placeholder="01:30:00"
                onChange={(e) => setPreparation_time(e.target.value)}
                className="preparation_time"
            /><br/>
            <label htmlFor="cooking_time">Elkészítési idő</label><br/>
            <input
                type="text"
                id="cooking_time"
                placeholder="01:30:00"
                values={cooking_time}
                onChange={(e) => setCooking_time(e.target.value)}
                className="cooking_time"
            /><br/>
            <label htmlFor="guide">Oktatóvideó</label><br/>
            <input
                type="url"
                id="guide"
                values={guide}
                onChange={(e) => setGuide(e.target.value)}
                className="guide"
            /><br/>

            <button className="recipeSubmit" type="submit">
            Hozzáadás
            </button>
            </form>
    </div>

}