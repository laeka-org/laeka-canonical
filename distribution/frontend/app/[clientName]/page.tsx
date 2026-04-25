import { notFound } from "next/navigation";
import { clientConfig } from "@/lib/client-config";
import { ThinkerShell } from "@/components/ThinkerShell";
import { ChatPanel } from "@/components/ChatPanel";

type Props = {
  params: Promise<{ clientName: string }>;
};

export default async function ClientChatPage({ params }: Props) {
  const { clientName } = await params;

  if (clientName !== clientConfig.clientName) {
    notFound();
  }

  return (
    <ThinkerShell clientName={clientName}>
      <ChatPanel userName={clientConfig.userName} />
    </ThinkerShell>
  );
}
