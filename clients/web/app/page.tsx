"use client";
import { SignedIn, SignedOut, SignInButton, UserButton } from "@clerk/nextjs";
import { useEffect, useMemo, useState } from "react";
import { Button } from "@/components/ui/button";

export default function Home() {
  const apiBase = useMemo(() => process.env.NEXT_PUBLIC_API_BASE_URL || "", []);
  const [status, setStatus] = useState<"idle" | "ok" | "fail">("idle");
  const [message, setMessage] = useState<string>("");
  const [usedToken, setUsedToken] = useState<boolean>(false);

  useEffect(() => {
    let cancelled = false;
    async function probe() {
      try {
        const resp = await fetch(`/api/health`, { cache: "no-store" });
        const data = await resp.json().catch(() => ({} as any));
        const ok = resp.ok && data?.ok !== false;
        if (cancelled) return;
        setUsedToken(Boolean(data?.usedToken));
        setStatus(ok ? "ok" : "fail");
        setMessage(ok ? "Connected" : `HTTP ${resp.status}`);
      } catch (err: any) {
        if (cancelled) return;
        setUsedToken(false);
        setStatus("fail");
        setMessage(err?.message || "Request failed");
      }
    }
    void probe();
    return () => {
      cancelled = true;
    };
  }, [apiBase]);

  const badgeClass =
    status === "ok"
      ? "bg-green-100 text-green-800 border-green-200"
      : status === "fail"
      ? "bg-red-100 text-red-800 border-red-200"
      : "bg-neutral-100 text-neutral-800 border-neutral-200";

  return (
    <main className="p-6 font-sans">
      <header className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-semibold">Welcome</h1>
        <div>
          <SignedIn>
            <UserButton />
          </SignedIn>
          <SignedOut>
            <SignInButton mode="modal">
              <Button>Sign in</Button>
            </SignInButton>
          </SignedOut>
        </div>
      </header>
      <div className="space-y-2">
        <p className="text-sm text-neutral-600">App router starter in clients/web.</p>
        {apiBase && (
          <p className="mt-2 text-sm">
            Backend: <code className="bg-neutral-100 px-1 py-0.5 rounded">{apiBase}</code>
          </p>
        )}
        <div className="mt-4 inline-flex items-center gap-2 rounded border px-3 py-1 text-sm font-medium select-none {badgeClass}">
          <span
            className={`inline-flex items-center gap-2 rounded border px-2 py-1 ${badgeClass}`}
            aria-live="polite"
          >
            {status === "ok" ? "Backend reachable" : status === "fail" ? "Backend error" : "Backend status"}
          </span>
          <span className="text-xs text-neutral-600">
            {status === "idle" ? message : usedToken ? "using token" : "no token"}
          </span>
        </div>
      </div>
    </main>
  );
}
