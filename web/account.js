import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY } from "./supabase-config.js";

const $ = (id) => document.getElementById(id);
const configReady = /^https:\/\/[a-z0-9-]+\.supabase\.co$/i.test(SUPABASE_URL) && SUPABASE_PUBLISHABLE_KEY.startsWith("sb_publishable_");
const configWarning = $("config-warning");
const message = $("message");
const authView = $("auth-view");
const profileView = $("profile-view");
const recoveryView = $("recovery-view");
let mode = "login";
let supabase = null;

function showMessage(text, kind = "info") {
  message.textContent = text;
  message.className = "notice" + (kind === "error" ? " error" : kind === "success" ? " success" : "");
  message.hidden = false;
}
function clearMessage() { message.hidden = true; message.textContent = ""; }
function setBusy(busy) {
  $("submit-button").disabled = busy;
  $("magic-button").disabled = busy;
  $("submit-label").textContent = busy ? "Подожди…" : mode === "signup" ? "Создать OTKAT ID" : "Войти в OTKAT ID";
}
function accountRedirect() {
  const url = new URL("./account.html", window.location.href);
  return url.href;
}
function setMode(nextMode) {
  mode = nextMode;
  $("tab-login").classList.toggle("active", mode === "login");
  $("tab-signup").classList.toggle("active", mode === "signup");
  $("name-wrap").hidden = mode !== "signup";
  $("password").autocomplete = mode === "signup" ? "new-password" : "current-password";
  $("forgot-button").hidden = mode === "signup";
  $("submit-label").textContent = mode === "signup" ? "Создать OTKAT ID" : "Войти в OTKAT ID";
  clearMessage();
}
function showAuth() {
  authView.hidden = false;
  profileView.hidden = true;
  recoveryView.hidden = true;
}
async function renderSession(user) {
  if (!user) {
    showAuth();
    return;
  }
  authView.hidden = true;
  recoveryView.hidden = true;
  profileView.hidden = false;
  const meta = user.user_metadata || {};
  const name = meta.display_name || meta.username || "Пользователь OTKAT";
  $("profile-name").textContent = name;
  $("profile-email").textContent = user.email || "";
  $("profile-id").textContent = user.id;
  $("profile-avatar").textContent = (name.trim()[0] || "O").toUpperCase();
  // Read only: the current stage does not create or alter profile rows.
  const { data: profile, error } = await supabase
    .from("profiles")
    .select("username, display_name, avatar_key")
    .eq("id", user.id)
    .maybeSingle();
  if (!error && profile) {
    $("profile-name").textContent = profile.display_name || profile.username || name;
    $("profile-avatar").textContent = (profile.display_name || profile.username || name).trim()[0].toUpperCase();
  }
}
async function boot() {
  if (!configReady) {
    configWarning.hidden = false;
    $("submit-button").disabled = true;
    $("magic-button").disabled = true;
    return;
  }
  supabase = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
    auth: { autoRefreshToken: true, persistSession: true, detectSessionInUrl: true }
  });
  const { data: { session }, error } = await supabase.auth.getSession();
  if (error) showMessage(error.message, "error");
  await renderSession(session?.user || null);
  supabase.auth.onAuthStateChange((event, sessionState) => {
    if (event === "PASSWORD_RECOVERY") {
      authView.hidden = true;
      profileView.hidden = true;
      recoveryView.hidden = false;
      clearMessage();
      return;
    }
    queueMicrotask(() => { void renderSession(sessionState?.user || null); });
  });
}
$("tab-login").addEventListener("click", () => setMode("login"));
$("tab-signup").addEventListener("click", () => setMode("signup"));
$("toggle-password").addEventListener("click", () => {
  const input = $("password");
  input.type = input.type === "password" ? "text" : "password";
});
$("auth-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  clearMessage();
  if (!supabase) return showMessage("Подключение Supabase ещё не настроено.", "error");
  const email = $("email").value.trim();
  const password = $("password").value;
  setBusy(true);
  try {
    if (mode === "signup") {
      const displayName = $("display-name").value.trim();
      const { data, error } = await supabase.auth.signUp({
        email, password,
        options: { emailRedirectTo: accountRedirect(), data: { display_name: displayName || email.split("@")[0] } }
      });
      if (error) throw error;
      if (data.session?.user) await renderSession(data.session.user);
      else showMessage("Почти готово! Проверь почту и подтверди адрес по ссылке. После подтверждения вернись на эту страницу и войди.", "success");
    } else {
      const { data, error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) throw error;
      await renderSession(data.user);
      showMessage("Вход выполнен. Добро пожаловать в OTKAT ID!", "success");
    }
  } catch (error) {
    showMessage(error.message || "Не удалось выполнить запрос. Попробуй ещё раз.", "error");
  } finally { setBusy(false); }
});
$("magic-button").addEventListener("click", async () => {
  clearMessage();
  if (!supabase) return showMessage("Подключение Supabase ещё не настроено.", "error");
  const email = $("email").value.trim();
  if (!email) return showMessage("Сначала введи Email.", "error");
  $("magic-button").disabled = true;
  try {
    const { error } = await supabase.auth.signInWithOtp({ email, options: { emailRedirectTo: accountRedirect(), shouldCreateUser: false } });
    if (error) throw error;
    showMessage("Ссылка для входа отправлена на почту. Открой письмо и перейди по ссылке.", "success");
  } catch (error) { showMessage(error.message || "Не удалось отправить ссылку.", "error"); }
  finally { $("magic-button").disabled = false; }
});
$("forgot-button").addEventListener("click", async () => {
  clearMessage();
  if (!supabase) return showMessage("Подключение Supabase ещё не настроено.", "error");
  const email = $("email").value.trim();
  if (!email) return showMessage("Введи Email, на который зарегистрирован аккаунт.", "error");
  try {
    const { error } = await supabase.auth.resetPasswordForEmail(email, { redirectTo: accountRedirect() });
    if (error) throw error;
    showMessage("Если аккаунт существует, письмо для восстановления пароля отправлено.", "success");
  } catch (error) { showMessage(error.message || "Не удалось отправить письмо.", "error"); }
});
$("recovery-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  const password = $("new-password").value;
  try {
    const { error } = await supabase.auth.updateUser({ password });
    if (error) throw error;
    recoveryView.hidden = true;
    showAuth();
    showMessage("Пароль обновлён. Теперь можно войти.", "success");
  } catch (error) { showMessage(error.message || "Не удалось обновить пароль.", "error"); }
});
$("copy-id").addEventListener("click", async () => {
  try { await navigator.clipboard.writeText($("profile-id").textContent); showMessage("OTKAT User ID скопирован.", "success"); }
  catch { showMessage("Не удалось скопировать ID автоматически. Выдели его и скопируй вручную.", "error"); }
});
$("signout-button").addEventListener("click", async () => {
  const { error } = await supabase.auth.signOut();
  if (error) showMessage(error.message, "error");
  else { showAuth(); showMessage("Ты вышел из аккаунта.", "success"); }
});
boot();
