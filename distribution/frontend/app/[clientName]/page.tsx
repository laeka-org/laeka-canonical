import { notFound } from "next/navigation";
import { clientConfig } from "@/lib/client-config";
import { ThinkerShell } from "@/components/ThinkerShell";
import { ChatPanel } from "@/components/ChatPanel";

type Props = {
  params: Promise<{ clientName: string }>;
};

const ALLOWED_CLIENTS = new Set([clientConfig.clientName, "bhairava"]);

export default async function ClientChatPage({ params }: Props) {
  const { clientName } = await params;

  if (!ALLOWED_CLIENTS.has(clientName)) {
    notFound();
  }

  const userName =
    clientName === "bhairava" ? "Bhairava" : clientConfig.userName;

  return (
    <ThinkerShell clientName={clientName}>
      <ChatPanel userName={userName} clientName={clientName} />
    </ThinkerShell>
  );
}
