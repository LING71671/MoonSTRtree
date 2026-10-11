import {
  createContext,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from "react";
import { en } from "./en";
import { zh } from "./zh";

export type Locale = "en" | "zh";
const storageKey = "moon-strtree:locale";
const dictionaries = { en, zh };
const Context = createContext<{
  locale: Locale;
  setLocale: (locale: Locale) => void;
  copy: typeof en;
  number: (value: number) => string;
} | null>(null);

export function LocaleProvider({ children }: { children: ReactNode }) {
  const [locale, setLocale] = useState<Locale>(() => {
    try {
      return localStorage.getItem(storageKey) === "en" ? "en" : "zh";
    } catch {
      return "zh";
    }
  });
  const copy = dictionaries[locale];
  useEffect(() => {
    document.documentElement.lang = locale === "zh" ? "zh-CN" : "en";
    document.title = copy.pageTitle;
    document
      .querySelector('meta[name="description"]')
      ?.setAttribute("content", copy.pageDescription);
    try {
      localStorage.setItem(storageKey, locale);
    } catch {
      /* Language switching still works without persistent storage. */
    }
  }, [locale, copy]);
  return (
    <Context.Provider
      value={{
        locale,
        setLocale,
        copy,
        number: (value) =>
          value.toLocaleString(locale === "zh" ? "zh-CN" : "en-US"),
      }}
    >
      {children}
    </Context.Provider>
  );
}

export function useLocale() {
  const value = useContext(Context);
  if (!value) throw new Error("LocaleProvider is required.");
  return value;
}
