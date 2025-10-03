"use client";
import { SignedIn, SignedOut, SignInButton, UserButton } from "@clerk/nextjs";
import { Button } from "@/components/ui/button";

export default function Home() {
  const apiBase = process.env.NEXT_PUBLIC_API_BASE_URL || "";
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
      <p className="text-sm text-neutral-600">App router starter in clients/web.</p>
      {apiBase && (
        <p className="mt-2 text-sm">
          Backend: <code className="bg-neutral-100 px-1 py-0.5 rounded">{apiBase}</code>
        </p>
      )}
    </main>
  );
}
