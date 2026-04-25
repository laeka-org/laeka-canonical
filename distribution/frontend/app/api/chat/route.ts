import { spawn } from "child_process";
import type { NextRequest } from "next/server";
import { clientConfig } from "@/lib/client-config";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

type ChatMessage = {
  role: "user" | "assistant";
  content: string;
};

function buildPrompt(messages: ChatMessage[]): string {
  if (messages.length === 1) {
    return messages[0].content;
  }
  const historyLines = messages.slice(0, -1).map(
    (m) => `${m.role === "user" ? "User" : "Laeka"}: ${m.content}`,
  );
  const history = historyLines.join("\n\n");
  const current = messages[messages.length - 1].content;
  return `[Conversation history]\n${history}\n\n[Current message]\n${current}`;
}

function sseFrame(data: unknown): Uint8Array {
  return new TextEncoder().encode(`data: ${JSON.stringify(data)}\n\n`);
}

function sseDone(): Uint8Array {
  return new TextEncoder().encode("data: [DONE]\n\n");
}

export async function POST(request: NextRequest) {
  let body: { messages?: ChatMessage[]; clientName?: string };
  try {
    body = await request.json();
  } catch {
    return new Response(JSON.stringify({ error: "invalid_json" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const messages = Array.isArray(body.messages) ? body.messages : [];
  const cleanMessages = messages.filter(
    (m) =>
      m &&
      (m.role === "user" || m.role === "assistant") &&
      typeof m.content === "string" &&
      m.content.length > 0,
  );

  if (cleanMessages.length === 0) {
    return new Response(JSON.stringify({ error: "empty_messages" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const prompt = buildPrompt(cleanMessages);

  const args = ["--print"];
  const model = clientConfig.claudeModel || process.env.CLAUDE_MODEL;
  if (model) {
    args.push("--model", model);
  }

  // Bhairava route → public sanitized HOME (no Saphi PII, only ontological corpus)
  // Other routes → process HOME (full Laeka with private memories)
  const isBhairava = body.clientName === "bhairava";
  const subprocessEnv = isBhairava
    ? { ...process.env, HOME: "/tmp/laeka-public-home" }
    : { ...process.env };

  const readable = new ReadableStream({
    start(controller) {
      const child = spawn("claude", args, {
        stdio: ["pipe", "pipe", "pipe"],
        env: subprocessEnv,
      });

      child.stdin.write(prompt, "utf8");
      child.stdin.end();

      child.stdout.on("data", (chunk: Buffer) => {
        const text = chunk.toString("utf8");
        controller.enqueue(sseFrame({ type: "text", delta: text }));
      });

      child.stdout.on("end", () => {
        controller.enqueue(sseDone());
        controller.close();
      });

      child.stderr.on("data", (chunk: Buffer) => {
        const msg = chunk.toString("utf8").trim();
        if (msg) console.error("[claude subprocess]", msg);
      });

      child.on("error", (err) => {
        controller.enqueue(sseFrame({ type: "error", message: err.message }));
        controller.close();
      });

      child.on("close", (code) => {
        if (code !== 0 && code !== null) {
          console.error("[claude subprocess] exit code", code);
        }
      });
    },
  });

  return new Response(readable, {
    headers: {
      "Content-Type": "text/event-stream; charset=utf-8",
      "Cache-Control": "no-cache, no-transform",
      Connection: "keep-alive",
      "X-Accel-Buffering": "no",
    },
  });
}
