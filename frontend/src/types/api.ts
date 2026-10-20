export type ApiMeta = { apiVersion: string; requestId: string; timestamp?: string };
export type ApiSuccess<T> = { ok: true; data: T; meta: ApiMeta };
export type ApiFailure = { ok: false; error: { code: string; message: string; details?: unknown[] }; meta?: ApiMeta };
export type ApiResponse<T> = ApiSuccess<T> | ApiFailure;

export type User = { id: string; name: string; email: string; role: string; initials: string; isPlatformAdmin?: boolean };
export type Workspace = { id: string; name: string; initials: string; plan: string; organizationType?: string; currency: string };
export type WorkspaceContext = { organization: Workspace; sector: { partyLabel: string; recordLabel: string; paymentLabel: string; description: string }; capabilities: string[]; rules: { currencyLockedAfterFirstInvoice: boolean; paymentCannotExceedBalance: boolean; tenantScoped: boolean } };
export type Invoice = {
  id: string;
  invoiceNumber: string;
  customerId: string;
  customerName: string;
  outstanding: number;
  amount: number;
  paidAmount: number;
  status: string;
  daysOverdue: number;
  daysUntilDue: number;
  issueDate: string;
  dueDate: string;
  description: string;
  purchaseOrder: string;
  promiseDate: string;
  disputeReason: string;
  reminderCount: number;
};
export type Customer = { id: string; name: string; contact: string; email: string; phone: string; initials: string; outstanding: number; overdue: number; paid: number; invoiceCount: number; health: string };
export type Session = { user: User; workspace: Workspace; csrfToken: string };
export type Dashboard = {
  organization: Workspace;
  outstanding: number;
  overdueAmount: number;
  overdueCount: number;
  dueSoonAmount: number;
  collectedAmount: number;
  collectionRate: number;
  customerCount: number;
  priorityInvoices: Invoice[];
  aging: { current: number; oneToThirty: number; thirtyOneToSixty: number; overSixty: number; total: number };
  forecast: { label: string; amount: number; confidence: number }[];
  recentActivity: { kind: string; title: string; detail: string; at: string }[];
};

export type Report = {
  aging: Dashboard["aging"];
  topCustomers: Customer[];
  collectionRate: number;
  avgDaysToPay: number;
  promiseKept: number;
  monthly: { label: string; billed: number; collected: number }[];
};

export type WorkspaceSettings = Workspace & { financeEmail: string; defaultTerms: number };
export type UserProfile = { name: string; email: string; initials: string; photoUrl: string; createdAt: string; lastLogin: string };
export type AdminWorkspace = { id: string; name: string; slug: string; email: string; createdAt: string; memberCount: number; invoiceCount: number; lastLogin: string; usage30d: number };
export type AdminOverview = { metrics: { workspaceCount: number; userCount: number; loginsToday: number; invoiceCount: number }; workspaces: AdminWorkspace[]; loginEvents: { email: string; name: string; outcome: string; at: string }[] };
export type AssistantStatus = { enabled: boolean; configured: boolean; keyCount: number; provider: string; model: string; mode: string };
export type AssistantEvidence = { source: string; type: string; detail: string; values: unknown };
export type AssistantAnswer = { answer: string; provider: string; model: string; mode: string; configured: boolean; evidence?: AssistantEvidence[]; nextActions?: string[] };
