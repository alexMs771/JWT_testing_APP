"use client";

import { ChangeEvent, FormEvent, useEffect, useState } from "react";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { ProductIcon } from "@/components/product-icon";
import { apiMutation, apiRequest } from "@/lib/api";
import type { UserProfile, WorkspaceSettings } from "@/types/api";

export default function ProfilePage() {
  const router = useRouter();
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [workspace, setWorkspace] = useState<WorkspaceSettings | null>(null);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [saving, setSaving] = useState(false);
  const [confirmation, setConfirmation] = useState("");

  useEffect(() => { let active = true; Promise.all([apiRequest<UserProfile>("/profile"), apiRequest<WorkspaceSettings>("/settings")]).then(([profileResult, workspaceResult]) => { if (!active) return; if (profileResult.ok) setProfile(profileResult.data); else setError(profileResult.error.message); if (workspaceResult.ok) setWorkspace(workspaceResult.data); else setError(workspaceResult.error.message); }); return () => { active = false; }; }, []);

  async function saveProfile(event: FormEvent<HTMLFormElement>) { event.preventDefault(); setSaving(true); setError(""); const result = await apiMutation<UserProfile>("/profile", { name: new FormData(event.currentTarget).get("name") }); setSaving(false); if (result.ok) { setProfile(result.data); setNotice("Profile updated."); } else setError(result.error.message); }
  async function uploadPhoto(event: ChangeEvent<HTMLInputElement>) { const file = event.target.files?.[0]; if (!file) return; setError(""); if (!/image\/(jpeg|png|webp)/.test(file.type) || file.size > 2 * 1024 * 1024) { setError("Choose a JPG, PNG, or WEBP image under 2 MB."); event.target.value = ""; return; } const reader = new FileReader(); reader.onload = async () => { const encoded = String(reader.result).split(",")[1] || ""; const result = await apiMutation<UserProfile>("/profile/photo", { contentType: file.type, imageBase64: encoded }); if (result.ok) { setProfile(result.data); setNotice("Profile photo updated."); } else setError(result.error.message); }; reader.readAsDataURL(file); }
  async function removePhoto() { const result = await apiMutation<UserProfile>("/profile/photo/remove", {}); if (result.ok) { setProfile(result.data); setNotice("Profile photo removed."); } else setError(result.error.message); }
  async function deleteWorkspace() { if (!workspace) return; setError(""); const result = await apiMutation<{ deleted: boolean }>("/workspace/delete", { confirmation }); if (result.ok) { router.replace("/login"); router.refresh(); } else setError(result.error.message); }

  if (!profile || !workspace) return <main className="product-page"><div className="skeleton heading-skeleton" />{error && <div className="form-error" role="alert">{error}</div>}</main>;
  return <main className="product-page"><div className="page-heading"><div><span className="page-eyebrow">Personal settings</span><h1>Your account, your workspace.</h1><p>Keep your identity current and manage the workspace you own.</p></div></div>{error && <div className="form-error" role="alert">{error}</div>}{notice && <div className="form-notice" role="status"><ProductIcon name="check" />{notice}</div>}<div className="settings-grid"><section className="panel settings-form"><header><div><span className="section-kicker">Profile</span><h2>How your team sees you</h2><p>Profile photos are stored privately with your account.</p></div></header><div className="profile-photo-row">{profile.photoUrl ? <Image src={profile.photoUrl} alt="Your profile" className="profile-photo" width={76} height={76} unoptimized /> : <span className="profile-photo profile-photo-placeholder">{profile.initials}</span>}<div><label className="button button-quiet upload-photo">Upload photo<input type="file" accept="image/jpeg,image/png,image/webp" onChange={uploadPhoto} /></label>{profile.photoUrl && <button className="text-danger" type="button" onClick={removePhoto}>Remove photo</button>}<small>JPG, PNG, or WEBP up to 2 MB.</small></div></div><form onSubmit={saveProfile}><label>Your full name<input name="name" defaultValue={profile.name} minLength={2} maxLength={120} required /></label><label>Work email<input value={profile.email} disabled aria-describedby="email-note" /></label><small id="email-note">Email changes require verification and support review.</small><div className="profile-meta"><span>Member since <b>{profile.createdAt}</b></span><span>Last sign-in <b>{profile.lastLogin}</b></span></div><footer><span>Your saved name appears throughout workspace activity.</span><button className="button button-primary" disabled={saving}>{saving ? "Saving..." : "Save profile"}</button></footer></form></section><aside className="settings-side"><section className="panel danger-card"><span className="section-kicker">Danger zone</span><h2>Delete this workspace</h2><p>Deleting <strong>{workspace.name}</strong> permanently removes its customers, invoices, payment history, and activity. This cannot be undone.</p><label>Type <b>{workspace.name}</b> to confirm<input value={confirmation} onChange={(event) => setConfirmation(event.target.value)} /></label><button className="button button-danger" type="button" disabled={confirmation !== workspace.name} onClick={deleteWorkspace}>Delete workspace</button></section></aside></div></main>;
}
