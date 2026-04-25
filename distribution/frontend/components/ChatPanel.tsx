"use client";

import { useEffect, useRef, useState } from "react";

export type Message = {
  role: "user" | "assistant";
  content: string;
};

type StoredConversation = {
  messages: Message[];
  lastUpdated: string;
};

type Props = {
  userName?: string;
  clientName?: string;
};

function storageKey(clientName?: string) {
  return `laeka_chat_${clientName || "default"}`;
}

function loadConversation(clientName?: string): StoredConversation | null {
  try {
    const raw = localStorage.getItem(storageKey(clientName));
    if (!raw) return null;
    const parsed = JSON.parse(raw) as StoredConversation;
    if (!Array.isArray(parsed.messages)) return null;
    return parsed;
  } catch {
    return null;
  }
}

function saveConversation(messages: Message[], clientName?: string) {
  try {
    const data: StoredConversation = {
      messages,
      lastUpdated: new Date().toISOString(),
    };
    localStorage.setItem(storageKey(clientName), JSON.stringify(data));
  } catch {
    // localStorage may be full or unavailable — silent fail
  }
}

function clearConversation(clientName?: string) {
  try {
    localStorage.removeItem(storageKey(clientName));
  } catch {
    // silent
  }
}

function formatRestoredDate(isoString: string): string {
  try {
    return new Date(isoString).toLocaleDateString(undefined, {
      month: "short",
      day: "numeric",
      year: "numeric",
    });
  } catch {
    return isoString;
  }
}

export function ChatPanel({ userName, clientName }: Props) {
  const [messages, setMessages] = useState<Message[]>([]);
  const [restoredDate, setRestoredDate] = useState<string | null>(null);
  const [input, setInput] = useState("");
  const [streaming, setStreaming] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const scrollRef = useRef<HTMLDivElement>(null);

  // Load from localStorage on mount (or when clientName changes)
  useEffect(() => {
    const stored = loadConversation(clientName);
    if (stored && stored.messages.length > 0) {
      setMessages(stored.messages);
      setRestoredDate(stored.lastUpdated);
    } else {
      setMessages([]);
      setRestoredDate(null);
    }
  }, [clientName]);

  // Save to localStorage after each complete exchange (guard: skip during streaming)
  useEffect(() => {
    if (streaming || messages.length === 0) return;
    const last = messages[messages.length - 1];
    if (last?.role === "assistant" && last.content === "") return;
    saveConversation(messages, clientName);
  }, [messages, streaming, clientName]);

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [messages, streaming]);

  function startNewConversation() {
    if (!confirm("Clear this conversation and start fresh?")) return;
    clearConversation(clientName);
    setMessages([]);
    setRestoredDate(null);
    setError(null);
  }

  async function send() {
    const text = input.trim();
    if (!text || streaming) return;

    setError(null);
    const next: Message[] = [
      ...messages,
      { role: "user", content: text },
      { role: "assistant", content: "" },
    ];
    setMessages(next);
    setInput("");
    setStreaming(true);

    try {
      const res = await fetch("/api/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          messages: next
            .slice(0, -1)
            .map((m) => ({ role: m.role, content: m.content })),
          clientName,
        }),
      });

      if (!res.ok || !res.body) {
        const body = await res.text().catch(() => "");
        throw new Error(
          `Chat API returned ${res.status}${body ? `: ${body}` : ""}`,
        );
      }

      const reader = res.body.getReader();
      const decoder = new TextDecoder();
      let buffer = "";

      while (true) {
        const { value, done } = await reader.read();
        if (done) break;
        buffer += decoder.decode(value, { stream: true });

        const frames = buffer.split("\n\n");
        buffer = frames.pop() ?? "";

        for (const frame of frames) {
          for (const line of frame.split("\n")) {
            if (!line.startsWith("data:")) continue;
            const payload = line.slice(5).trim();
            if (!payload || payload === "[DONE]") continue;

            try {
              const parsed = JSON.parse(payload);
              if (
                parsed.type === "text" &&
                typeof parsed.delta === "string"
              ) {
                setMessages((prev) => {
                  const copy = [...prev];
                  const last = copy[copy.length - 1];
                  if (last && last.role === "assistant") {
                    copy[copy.length - 1] = {
                      ...last,
                      content: last.content + parsed.delta,
                    };
                  }
                  return copy;
                });
              } else if (parsed.type === "error") {
                throw new Error(parsed.message ?? "stream error");
              }
            } catch (parseErr) {
              if (
                parseErr instanceof Error &&
                parseErr.message !== payload
              ) {
                throw parseErr;
              }
            }
          }
        }
      }
    } catch (err) {
      const msg = err instanceof Error ? err.message : "unknown error";
      setError(msg);
      setMessages((prev) => {
        const last = prev[prev.length - 1];
        if (last && last.role === "assistant" && last.content === "") {
          return prev.slice(0, -1);
        }
        return prev;
      });
    } finally {
      setStreaming(false);
    }
  }

  function onKeyDown(e: React.KeyboardEvent<HTMLTextAreaElement>) {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      send();
    }
  }

  return (
    <div className="flex-1 flex flex-col overflow-hidden">
      <div ref={scrollRef} className="flex-1 overflow-y-auto px-6 py-8">
        <div className="max-w-3xl mx-auto space-y-6">
          {messages.length === 0 && (
            <div className="text-center text-[var(--color-fg-muted)] py-16 space-y-2">
              <p className="font-mono text-xs tracking-widest text-[var(--color-gold)]">
                CANONICAL LOADED
              </p>
              <p className="text-sm">
                The satellite is listening. Write what you came here to think.
              </p>
              {userName && (
                <p className="font-mono text-[10px] tracking-widest opacity-40">
                  {userName.toUpperCase()}
                </p>
              )}
            </div>
          )}

          {messages.length > 0 && restoredDate && (
            <div className="text-center">
              <p className="font-mono text-[10px] tracking-widest text-[var(--color-fg-muted)] opacity-50">
                CONTINUED FROM {formatRestoredDate(restoredDate).toUpperCase()}
              </p>
            </div>
          )}

          {messages.map((m, i) => (
            <div
              key={i}
              className={
                m.role === "user" ? "flex justify-end" : "flex justify-start"
              }
            >
              <div
                className={
                  m.role === "user"
                    ? "max-w-[80%] rounded-2xl bg-[var(--color-bg-elev)] border border-[var(--color-border-subtle)] px-4 py-3 text-[var(--color-fg)]"
                    : "max-w-[85%] text-[var(--color-fg)] leading-relaxed"
                }
              >
                {m.role === "assistant" && (
                  <p className="mb-2 font-mono text-[11px] tracking-widest text-[var(--color-gold)]">
                    LAEKA
                  </p>
                )}
                <div className="whitespace-pre-wrap">
                  {m.content || (
                    <span className="text-[var(--color-fg-muted)] animate-pulse">
                      …
                    </span>
                  )}
                </div>
              </div>
            </div>
          ))}

          {error && (
            <div className="mx-auto max-w-2xl rounded-xl border border-red-400/30 bg-red-400/5 px-4 py-3 text-sm font-mono text-red-300">
              {error}
            </div>
          )}
        </div>
      </div>

      <div className="border-t border-[var(--color-border-subtle)] px-6 py-4">
        <div className="max-w-3xl mx-auto flex items-end gap-3">
          <textarea
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={onKeyDown}
            placeholder="Write to Laeka…"
            disabled={streaming}
            rows={1}
            className="flex-1 resize-none rounded-xl border border-[var(--color-border-subtle)] bg-[var(--color-bg-elev)] px-4 py-3 text-[var(--color-fg)] placeholder:text-[var(--color-fg-muted)] focus:border-[var(--color-gold)] focus:outline-none transition-colors max-h-48"
            style={{ minHeight: "48px" }}
          />
          <button
            type="button"
            onClick={send}
            disabled={streaming || !input.trim()}
            className="rounded-xl bg-[var(--color-gold)] px-5 py-3 text-sm font-medium text-[var(--color-bg)] hover:bg-[var(--color-fg)] transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
          >
            {streaming ? "…" : "Send"}
          </button>
        </div>
        <div className="mt-2 flex items-center justify-between max-w-3xl mx-auto">
          <p className="font-mono text-[10px] tracking-widest text-[var(--color-fg-muted)]">
            ENTER · SEND · SHIFT+ENTER · NEWLINE
          </p>
          {messages.length > 0 && (
            <button
              type="button"
              onClick={startNewConversation}
              className="font-mono text-[10px] tracking-widest text-[var(--color-fg-muted)] hover:text-[var(--color-gold)] transition-colors"
            >
              NEW CONVERSATION
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
