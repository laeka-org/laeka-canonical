import { redirect } from "next/navigation";
import { clientConfig } from "@/lib/client-config";

export default function RootPage() {
  redirect(`/${clientConfig.clientName}`);
}
