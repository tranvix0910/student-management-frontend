import axios from "axios";

const instance = axios.create({
  baseURL: window.REACT_APP_API_URL || "http://localhost:8080",
  headers: {
    "Content-type": "application/json"
  }
});

export default instance;
