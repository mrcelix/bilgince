import type { APIRoute } from 'astro';
import { silmeCerezi } from '../../../admin/oturum';

export const prerender = false;

const cik = () =>
  new Response(null, {
    status: 302,
    headers: { location: '/admin/giris', 'set-cookie': silmeCerezi() },
  });

export const GET: APIRoute = cik;
export const POST: APIRoute = cik;
