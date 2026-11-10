/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_URL?: string;
  readonly VITE_MAPBOX_ACCESS_TOKEN?: string;
  readonly VITE_ANDROID_APK_URL?: string;
  readonly VITE_ANDROID_APK_VERSION?: string;
  readonly VITE_ANDROID_APK_SIZE?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}

