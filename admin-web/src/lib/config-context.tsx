"use client";

import {
  createContext,
  useContext,
  useEffect,
  useState,
  useRef,
  useCallback,
  type ReactNode,
} from "react";
import { supabase, fetchAllConfig, updateConfigKey } from "./supabase";

type ConfigCtx = {
  config: Record<string, string>;
  loading: boolean;
  adminEmail: string;
  save: (key: string, value: string) => Promise<void>;
  saveBatch: (entries: Record<string, string>) => Promise<void>;
};

const Ctx = createContext<ConfigCtx>({
  config: {},
  loading: true,
  adminEmail: "",
  save: async () => {},
  saveBatch: async () => {},
});

export function useConfig() {
  return useContext(Ctx);
}

export function ConfigProvider({ children }: { children: ReactNode }) {
  const [config, setConfig] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);
  const emailRef = useRef("");

  useEffect(() => {
    Promise.all([fetchAllConfig(), supabase.auth.getUser()]).then(
      ([rows, { data }]) => {
        const map: Record<string, string> = {};
        for (const r of rows) map[r.key] = r.value;
        setConfig(map);
        emailRef.current = data.user?.email ?? "admin";
        setLoading(false);
      }
    );
  }, []);

  const save = useCallback(async (key: string, value: string) => {
    setConfig((prev) => ({ ...prev, [key]: value }));
    await updateConfigKey(key, value, emailRef.current);
  }, []);

  const saveBatch = useCallback(async (entries: Record<string, string>) => {
    setConfig((prev) => ({ ...prev, ...entries }));
    await Promise.all(
      Object.entries(entries).map(([k, v]) =>
        updateConfigKey(k, v, emailRef.current)
      )
    );
  }, []);

  return (
    <Ctx.Provider
      value={{ config, loading, adminEmail: emailRef.current, save, saveBatch }}
    >
      {children}
    </Ctx.Provider>
  );
}
