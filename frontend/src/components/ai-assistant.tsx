"use client";

import { FormEvent, useCallback, useEffect, useState } from "react";
import { usePathname } from "next/navigation";
import { ProductIcon } from "@/components/product-icon";
import { apiMutation, apiRequest } from "@/lib/api";
import type { AssistantAnswer, AssistantStatus } from "@/types/api";

type ChatMessage = {
  role: "user" | "assistant";
  content: string;
  evidence?: AssistantAnswer["evidence"];
  nextActions?: string[];
};

export function AiAssistant({ open, onClose }: { open: boolean; onClose: () => void }) {
  const pathname = usePathname();
  const [status, setStatus] = useState<AssistantStatus | null>(null);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [pending, setPending] = useState(false);
  const [error, setError] = useState("");

  const loadStatus = useCallback(async () => {
    if (status) return;
    const result = await apiRequest<AssistantStatus>("/assistant/status");
    if (result.ok) setStatus(result.data);
    else setError(result.error.message);
  }, [status]);

  useEffect(() => {
    if (!open || status) return;
    const timer = window.setTimeout(() => void loadStatus(), 0);
    return () => window.clearTimeout(timer);
  }, [loadStatus, open, status]);

  async function ask(message: string) {
    const cleanMessage = message.trim();
    if (!cleanMessage || pending) return;

    const history = messages.slice(-8);
    setMessages((previous) => [...previous, { role: "user", content: cleanMessage }]);
    setPending(true);
    setError("");
    const result = await apiMutation<AssistantAnswer>("/assistant/chat", { message: cleanMessage, history, context: { page: pathname } });
    if (result.ok) {
      setMessages((previous) => [...previous, { role: "assistant", content: result.data.answer, evidence: result.data.evidence, nextActions: result.data.nextActions }]);
      if (!status) void loadStatus();
    } else {
      setError(result.error.message);
    }
    setPending(false);
  }

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const formElement = event.currentTarget;
    const message = String(new FormData(formElement).get("message") || "");
    formElement.reset();
    await ask(message);
  }

  if (!open) return null;

  const suggestions = ["What should I collect today?", "Explain my aging risk", "Draft a respectful reminder"];

  return <aside className="ai-drawer" aria-label="DuePilot AI assistant">
    <header><div><span className="ai-overline"><ProductIcon name="sparkle" /> Finance intelligence</span><h2>Ask DuePilot</h2><p>Clear guidance grounded in your workspace.</p></div><div className="ai-header-actions"><button type="button" className="ai-clear" onClick={() => setMessages([])} disabled={!messages.length}>Clear chat</button><button type="button" className="icon-button" onClick={onClose} aria-label="Close assistant"><ProductIcon name="close" /></button></div></header>
    <div className="ai-mode"><i /><span>{status?.mode === "live" ? "Live AI connected" : "Guided workspace mode"}</span><small>{status?.model || "Secure server-side"}</small></div>
    <div className="ai-messages" aria-live="polite">
      {!messages.length && <div className="ai-welcome"><span className="ai-orb"><ProductIcon name="sparkle" /></span><h3>What needs attention?</h3><p>I read the current workspace context, cite the evidence used, and keep provider credentials on the server.</p><div>{suggestions.map((item) => <button key={item} type="button" onClick={() => void ask(item)}><ProductIcon name="arrow" />{item}</button>)}</div></div>}
      {messages.map((message, index) => <article className={message.role} key={`${message.role}-${index}`}><small>{message.role === "assistant" ? "DuePilot intelligence" : "You"}</small><p>{message.content}</p>{message.role === "assistant" && <>{Boolean(message.evidence?.length) && <div className="ai-evidence"><strong>Workspace evidence</strong>{message.evidence?.map((item) => <span key={`${item.source}-${item.type}`}><i /><b>{item.source}</b><small>{item.detail}</small></span>)}</div>}{Boolean(message.nextActions?.length) && <div className="ai-next"><strong>Recommended next moves</strong><ol>{message.nextActions?.map((item) => <li key={item}>{item}</li>)}</ol></div>}</>}</article>)}
      {pending && <article className="assistant pending"><small>DuePilot intelligence</small><p>Reviewing the relevant receivables and activity…</p></article>}
      {error && <div className="ai-error" role="alert">{error}</div>}
    </div>
    <form onSubmit={submit}><textarea name="message" aria-label="Message DuePilot AI" required maxLength={2000} placeholder="Ask about priorities, a customer, or a payment follow-up…" /><footer><small>Review financial decisions before acting.</small><button disabled={pending} className="button button-primary">Send <ProductIcon name="arrow" /></button></footer></form>
  </aside>;
}
