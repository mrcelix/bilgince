/// <reference types="astro/client" />

declare namespace App {
  interface Locals {
    /** Yönetim paneli oturumu — middleware dolduruyor. */
    oturum?: import('./admin/oturum').Oturum;
  }
}

interface ImportMetaEnv {
  readonly GOOGLE_ISTEMCI_ID?: string;
  readonly GOOGLE_ISTEMCI_SIR?: string;
  readonly OTURUM_ANAHTARI?: string;
  readonly ADMIN_EPOSTALAR?: string;
  readonly GITHUB_JETON?: string;
  readonly GITHUB_DEPO?: string;
  readonly GITHUB_DAL?: string;
  readonly CLOUDFLARE_ACCOUNT_ID?: string;
  readonly CLOUDFLARE_AI_TOKEN?: string;
  readonly CLOUDFLARE_TARAYICI_TOKEN?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
