import config from "@/config/client-config.json";

export type ClientConfig = {
  clientName: string;
  port: number;
  userName: string;
  claudeModel: string;
};

export const clientConfig: ClientConfig = config as ClientConfig;
