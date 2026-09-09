import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    host: true,
    port: 5173,
    // Les bind-mounts Docker sous Windows/macOS ne propagent pas les événements
    // inotify : sans polling, le HMR ne se déclenche jamais.
    watch: { usePolling: true, interval: 300 },
  },
});
