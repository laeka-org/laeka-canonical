"use client";

import Link from "next/link";

type Props = {
  clientName: string;
  children: React.ReactNode;
};

export function ThinkerShell({ clientName, children }: Props) {
  return (
    <main className="flex flex-1 flex-col h-screen">
      <header className="flex items-center justify-between border-b border-[var(--color-border-subtle)] px-6 py-3">
        <Link
          href={`/${clientName}`}
          className="font-mono text-xs tracking-[0.3em] text-[var(--color-gold)] hover:text-[var(--color-fg)] transition-colors"
        >
          LAEKA · {clientName.toUpperCase()}
        </Link>
        <div className="flex items-center gap-4 text-xs text-[var(--color-fg-muted)]">
          <span className="font-mono text-[10px] tracking-widest opacity-40">
            LOCAL
          </span>
        </div>
      </header>

      <div className="flex-1 flex overflow-hidden">
        <div className="flex-1 flex flex-col overflow-hidden">{children}</div>
      </div>
    </main>
  );
}
