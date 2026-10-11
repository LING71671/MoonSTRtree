import React from "react";
import ReactDOM from "react-dom/client";
import "@fontsource/barlow-condensed/600.css";
import "@fontsource-variable/manrope";
import "@fontsource-variable/noto-sans-sc";
import "./style.css";
import App from "./App";
import { LocaleProvider } from "./i18n/LocaleProvider";

ReactDOM.createRoot(document.getElementById("app")!).render(
  <React.StrictMode>
    <LocaleProvider>
      <App />
    </LocaleProvider>
  </React.StrictMode>,
);
