export async function GET() {
  const base = process.env.NEXT_PUBLIC_API_BASE_URL;
  if (!base) {
    return Response.json(
      { ok: false, usedToken: false, status: 500, error: "NEXT_PUBLIC_API_BASE_URL not set" },
      { status: 500 }
    );
  }
  const token = process.env.API_TOKEN;
  const url = `${base.replace(/\/$/, "")}/v1/health`;
  try {
    const res = await fetch(url, {
      headers: token ? { Authorization: `Bearer ${token}` } : undefined,
      cache: "no-store"
    });
    return Response.json({ ok: res.ok, usedToken: Boolean(token), status: res.status }, { status: res.ok ? 200 : res.status });
  } catch (err: any) {
    return Response.json(
      { ok: false, usedToken: Boolean(token), status: 500, error: err?.message || "request failed" },
      { status: 500 }
    );
  }
}

