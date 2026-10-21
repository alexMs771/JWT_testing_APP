export type ApiMeta = { apiVersion: string; requestId: string; timestamp?: string };
export type ApiSuccess<T> = { ok: true; data: T; meta: ApiMeta };
export type ApiFailure = { ok: false; error: { code: string; message: string; details?: unknown[] }; meta?: ApiMeta };
export type ApiResponse<T> = ApiSuccess<T> | ApiFailure;

export type PlanAccess = { plan: "free" | "plus" | "pro" | string; subscriptionStatus: string; subscriptionId?: string; startsAt?: string; expiresAt?: string; isPaid: boolean; demoMode?: boolean; features: string[]; limits: { aiRequestsPerMonth: number; childWorkspaces: number }; usage: { aiRequestsThisMonth: number; aiRequestsRemaining: number }; workspace: { childCount: number; canCreateChild: boolean } };
export type PlanDefinition = { key: string; name: string; annualValidity: string; aiRequestsPerMonth: number; childWorkspaces: number; description: string };
export type User = { id: string; name: string; email: string; role: string; initials: string; plan?: string; subscriptionStatus?: string; subscriptionExpiresAt?: string; isPlatformAdmin?: boolean };
export type Workspace = { id: string; name: string; initials: string; plan: string; organizationType?: string; currency: string; parentWorkspaceId?: string };
export type WorkspaceNode = { id: string; name: string; slug: string; organizationType?: string; plan: string; parentWorkspaceId?: string };
export type WorkspaceUnit = { id: string; parentUnitId: string; name: string; code: string; unitType: string; createdAt: string };
export type WorkspaceContext = { organization: Workspace; sector: { partyLabel: string; recordLabel: string; paymentLabel: string; description: string }; capabilities: string[]; rules: { currencyLockedAfterFirstInvoice: boolean; paymentCannotExceedBalance: boolean; tenantScoped: boolean }; access?: PlanAccess; plans?: PlanDefinition[] };
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
export type Session = { user: User; workspace: Workspace; accessToken: string; access?: PlanAccess };
export type AccessPolicy = {
  verified: boolean;
  role: string;
  roles: string[];
  checks: {
    ownRole: boolean;
    operations: boolean;
    collections: boolean;
    workspaceAdmin: boolean;
    platformAdmin: boolean;
    platformOwner: boolean;
  };
  platform: { valid: boolean; authorized: boolean; code: string };
  plan?: string;
  subscriptionStatus?: string;
  subscriptionExpiresAt?: string;
  entitlements?: PlanAccess;
};
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
export type AdminWorkspace = { id: string; name: string; slug: string; organizationType?: string; plan?: string; email: string; createdAt: string; memberCount: number; invoiceCount: number; lastLogin: string; usage30d: number };
export type AdminOverview = { metrics: { workspaceCount: number; userCount: number; loginsToday: number; invoiceCount: number }; workspaces: AdminWorkspace[]; loginEvents: { email: string; name: string; outcome: string; at: string }[] };
export type AssistantStatus = { enabled: boolean; configured: boolean; keyCount: number; provider: string; model: string; mode: string; access?: PlanAccess };
export type AssistantEvidence = { source: string; type: string; detail: string; values: unknown };
export type AssistantAnswer = {
  answer: string;
  provider: string;
  model: string;
  mode: string;
  configured: boolean;
  evidence?: AssistantEvidence[];
  nextActions?: string[];
  intent?: string;
  retrievalMode?: string;
  retrievedCount?: number;
  confidence?: number;
  grounded?: boolean;
};
export type PersonalProfile = { displayName: string; mobileLast4: string; mobileVerified: boolean };
export type PersonalObligation = {
  id: string;
  providerName: string;
  category: string;
  title: string;
  externalReference: string;
  amount: number;
  paidAmount: number;
  balance: number;
  currency: string;
  issueDate: string;
  dueDate: string;
  status: string;
  daysUntilDue: number;
  daysOverdue: number;
};
export type PersonalSummary = {
  profile: PersonalProfile;
  connections: { id: string; providerName: string; category: string; status: string; lastSyncedAt: string }[];
  obligations: PersonalObligation[];
  summary: { totalOpen: number; overdueAmount: number; overdueCount: number; dueSoonAmount: number; paidAmount: number };
};
