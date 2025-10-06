"use client";
import Link from "next/link";
import type { Route } from "next";
import { usePathname } from "next/navigation";
import { LayoutDashboard } from "lucide-react";
import { UserButton } from "@clerk/nextjs";
import { cn } from "@/lib/utils";

const items: { href: Route; label: string; icon: React.ComponentType<{ size?: number }> }[] = [
  { href: "/dashboard", label: "Dashboard", icon: LayoutDashboard }
];

export function Sidebar() {
  const pathname = usePathname();
  return (
    <div className="h-full flex flex-col">
      <div className="flex items-center justify-between px-4 h-14 border-b">
        <span className="font-semibold">App</span>
        <UserButton afterSignOutUrl="/" />
      </div>
      <nav className="p-2 space-y-1">
        {items.map((item) => {
          const Icon = item.icon;
          const active = pathname === item.href || pathname?.startsWith(item.href + "/");
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "flex items-center gap-2 rounded-md px-3 py-2 text-sm",
                active ? "bg-neutral-100 font-medium" : "hover:bg-neutral-50"
              )}
            >
              <Icon size={16} />
              <span>{item.label}</span>
            </Link>
          );
        })}
      </nav>
    </div>
  );
}
