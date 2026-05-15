// js/auth.js
console.log("🚀 auth.js が読み込まれました！");
const firebaseConfig = {
    apiKey: SHIOYA_CONFIG.FIREBASE_API_KEY, 
    authDomain: "shioya-shogi.firebaseapp.com",
    projectId: "shioya-shogi",
    storageBucket: "shioya-shogi.firebasestorage.app",
    messagingSenderId: "400460108408",
    appId: "1:400460108408:web:0d43db04b02cce5230538d",
    measurementId: "G-K9ZLW8L09J"
};

const capPlugins = (window.Capacitor && window.Capacitor.Plugins) ? window.Capacitor.Plugins : {};

if (!firebase.apps.length) {
    firebase.initializeApp(firebaseConfig);
}
const db = firebase.firestore();
db.settings({
    experimentalForceLongPolling: true
});
const auth = firebase.auth();

async function initRevenueCat() {
    const isNative = window.Capacitor && window.Capacitor.isNativePlatform();
    if (isNative) {
        try {
            // ✅ ここで Purchases を定義します
            const Purchases = window.Capacitor.Plugins.Purchases;
            await Purchases.configure({ apiKey: SHIOYA_CONFIG.REVENUECAT_API_KEY });
            console.log("✅ RevenueCat 初期化完了");
        } catch (e) {
            console.error("❌ RevenueCat 初期化エラー:", e);
        }
    }
}
initRevenueCat();

function safeAlert(msg, callback) {
    alert(msg);
    if (callback) callback();
}

function safeConfirm(msg, yesCallback) {
    if (confirm(msg)) {
        if (yesCallback) yesCallback();
    }
}

// ユーザー状態監視
auth.onAuthStateChanged(async (user) => {
    const authButtons = document.getElementById("authButtons");
    const loggedInStatusArea = document.getElementById("loggedInStatusArea");
    const userNameDisplay = document.getElementById("userNameDisplay");
    const loginProviderText = document.getElementById("loginProviderText");
    const userGoldDisplay = document.getElementById("userGoldDisplay");

    if (user) {
        const isNative = window.Capacitor && window.Capacitor.isNativePlatform();
        if (isNative) {
            const Purchases = window.Capacitor.Plugins.Purchases;
            await Purchases.logIn({ appUserID: user.uid });
        }
        const userRef = db.collection("users").doc(user.uid);
        const userDoc = await userRef.get();
        let displayName = user.displayName;

        if (userDoc.exists) {
            const data = userDoc.data();
            if (!displayName && data.name) displayName = data.name;
            if (userGoldDisplay && data.gold !== undefined) {
                userGoldDisplay.innerText = data.gold;
            }
        }
        if (!displayName) displayName = user.email.split("@")[0];

        if (authButtons) authButtons.style.display = "none";
        if (loggedInStatusArea) {
            loggedInStatusArea.style.display = "block";
            if (userNameDisplay) userNameDisplay.innerText = displayName;
        }

        if (loginProviderText) {
            let providerName = "しおやアカウント";
            if (user.providerData && user.providerData.length > 0) {
                const pid = user.providerData[0].providerId;
                if (pid === "google.com") providerName = "Google";
                else if (pid === "apple.com") providerName = "Apple";
            }
            loginProviderText.innerText = providerName;
        }
    } else {
        const isNative = window.Capacitor && window.Capacitor.isNativePlatform();
        if (isNative) {
            const Purchases = window.Capacitor.Plugins.Purchases;
            await Purchases.logOut();
        }
        
        if (authButtons) authButtons.style.display = "flex";
        if (loggedInStatusArea) loggedInStatusArea.style.display = "none";
    }
});

function showAuthModal() {
    console.log("🛠 showAuthModal がクリックされました！");
    const modal = document.getElementById("authModal");
    
    if (modal) {
        // 直接 style をいじるのではなく、クラスを追加する
        modal.classList.add('show');
        console.log("✅ モーダルに .show クラスを追加しました");
    } else {
        console.error("❌ 'authModal' という ID の要素が見つかりません！");
    }
}
function closeAuthModal() {
    const modal = document.getElementById("authModal");
    if (modal) {
        // クラスを削除する
        modal.classList.remove('show');
        console.log("✅ モーダルから .show クラスを削除しました");
    }
}

// registerUser 関数の中身を以下のように更新
function registerUser() {
    const email = document.getElementById("authEmail").value;
    const pass = document.getElementById("authPass").value;
    const tempName = "新規ユーザー"; 

    if (!email || !pass) { 
        safeAlert("メールとパスワードを入力してください"); 
        return; 
    }

    auth.createUserWithEmailAndPassword(email, pass).then((cred) => {
        const user = cred.user;
        user.updateProfile({ displayName: tempName }).then(() => {
            return db.collection("users").doc(user.uid).set({
                name: tempName, 
                email: email, 
                createdAt: firebase.firestore.FieldValue.serverTimestamp(),
                gold: 100, // 共通ポイント
                // ▼ ミュージック用の初期設定を追加
                ownedMusicIcons: ['icon-default'],
                ownedMusicThemes: ['theme-default'],
                currentMusicIcon: 'icon-default',
                currentMusicTheme: 'theme-default'
            }, { merge: true });
        }).then(() => {
            // ... (以下、名前入力モーダルの処理などはそのまま)
            safeAlert("登録ありがとうございます！\nあなたのお名前を教えてください！", () => {
                closeAuthModal();
                setTimeout(() => {
                    showNameEditModal();
                }, 300);
            });
        });
    }).catch((error) => { 
        let msg = "登録失敗: " + error.message;
        if (error.code === "auth/email-already-in-use") msg = "そのメールアドレスは既に使用されています。";
        if (error.code === "auth/weak-password") msg = "パスワードは6文字以上にしてください。";
        safeAlert(msg); 
    });
}

function loginUser() {
    const email = document.getElementById("authEmail").value;
    const pass = document.getElementById("authPass").value;
    if (!email || !pass) { safeAlert("メールとパスワードを入力してください"); return; }
    
    auth.signInWithEmailAndPassword(email, pass).then(async (cred) => {
        const doc = await db.collection("users").doc(cred.user.uid).get();
        const userName = doc.exists ? (doc.data().name || "ユーザー") : "ユーザー";
        safeAlert(`${userName} さんとしてログインしました！`, () => {
            closeAuthModal();
        });
    }).catch((error) => { 
        safeAlert("ログインに失敗しました。\nメールアドレスかパスワードが間違っています。"); 
    });
}

function logoutUser() {
    safeConfirm("ログアウトしますか？", () => {
        auth.signOut().then(() => { 
            safeAlert("ログアウトしました。", () => {
                closeAuthModal();
            });
        });
    });
}

function showNameEditModal() {
    const user = auth.currentUser;
    if (!user) return;
    
    const currentName = document.getElementById("userNameDisplay") ? document.getElementById("userNameDisplay").textContent : "";
    document.getElementById("newNameInput").value = currentName;
    
    const modal = document.getElementById("nameEditModal");
    if (modal) {
        // .style.display ではなく .classList.add を使う
        modal.classList.add('show');
        console.log("✅ 名前変更モーダルを表示しました");
    }
}

function closeNameEditModal() { 
    const modal = document.getElementById("nameEditModal");
    if (modal) {
        // .style.display ではなく .classList.remove を使う
        modal.classList.remove('show');
    }
}

function saveNewName() {
    const user = auth.currentUser;
    const inputEl = document.getElementById("newNameInput");
    const newName = inputEl ? inputEl.value.trim() : "";
    
    if (!newName) {
        safeAlert("名前を入力してください"); 
        return;
    }
    if (newName.length > 8) {
        safeAlert("名前は8文字以内で入力してください"); 
        return;
    }

    user.updateProfile({ displayName: newName }).then(() => {
        return db.collection("users").doc(user.uid).set({ name: newName }, { merge: true });
    }).then(() => {
        const nameDisplay = document.getElementById("userNameDisplay");
        if(nameDisplay) nameDisplay.textContent = newName;
        closeNameEditModal();
        safeAlert("「" + newName + "」さん、\nよろしくお願いいたします！");
    });
}

// setupSocialUser 関数の中身を以下のように更新
async function setupSocialUser(user) {
    const userRef = db.collection("users").doc(user.uid);
    const doc = await userRef.get();

    if (!doc.exists) {
        const tempName = user.displayName || "新規ユーザー";
        await userRef.set({
            name: tempName,
            email: user.email,
            createdAt: firebase.firestore.FieldValue.serverTimestamp(),
            gold: 100,
            // ▼ ミュージック用の初期設定を追加
            ownedMusicIcons: ['icon-default'],
            ownedMusicThemes: ['theme-default'],
            currentMusicIcon: 'icon-default',
            currentMusicTheme: 'theme-default'
        }, { merge: true });
        
        // ... (以下、アラート処理などはそのまま)
        
        safeAlert("登録ありがとうございます！\nまずはお名前を教えてください！", () => {
            closeAuthModal();
            setTimeout(() => {
                showNameEditModal();
            }, 300);
        });
    } else {
        safeAlert(`${doc.data().name || "ユーザー"} さんとしてログインしました！`, () => {
            closeAuthModal();
        });
    }
}

async function loginWithApple() {
    const isNative = window.Capacitor && window.Capacitor.isNativePlatform();
    try {
        if (isNative && capPlugins.AuthPlugin) {
            const result = await capPlugins.AuthPlugin.signInWithApple();
            const provider = new firebase.auth.OAuthProvider('apple.com');
            const credential = provider.credential({
                idToken: result.idToken,
                rawNonce: result.rawNonce
            });
            const resultAuth = await auth.signInWithCredential(credential);
            await setupSocialUser(resultAuth.user);
        } else {
            const provider = new firebase.auth.OAuthProvider('apple.com');
            const resultAuth = await auth.signInWithPopup(provider);
            await setupSocialUser(resultAuth.user);
        }
    } catch (error) {
        if (error.message && error.message.includes("cancel")) return;
        safeAlert("Appleログインに失敗しました。");
    }
}

async function loginWithGoogle() {
    const isNative = window.Capacitor && window.Capacitor.isNativePlatform();
    try {
        if (isNative && capPlugins.GoogleAuthPlugin) {
            const result = await capPlugins.GoogleAuthPlugin.signIn();
            const credential = firebase.auth.GoogleAuthProvider.credential(result.idToken, result.accessToken);
            const resultAuth = await auth.signInWithCredential(credential);
            await setupSocialUser(resultAuth.user);
        } else {
            const provider = new firebase.auth.GoogleAuthProvider();
            const resultAuth = await auth.signInWithPopup(provider);
            await setupSocialUser(resultAuth.user);
        }
    } catch (error) {
        if (error.message && error.message.includes("cancel")) return;
        safeAlert("Googleログインに失敗しました。");
    }
}

function deleteUserAccount() {
    safeConfirm("本当に退会（アカウント削除）しますか？\n※すべてのデータ・所持アイテムが消去され、復元できなくなります。", async () => {
        const confirmText = prompt("退会処理を続行する場合は「わかりました」と入力してOKを押してください。");
        if (confirmText !== "わかりました") {
            safeAlert("入力が一致しませんでした。\n退会処理をキャンセルしました。");
            return;
        }
        const user = auth.currentUser;
        if (!user) return;

        try {
            await db.collection("users").doc(user.uid).delete();
            await user.delete();
            safeAlert("アカウントを削除しました。\nご利用ありがとうございました。", () => {
                closeAuthModal();
            });
        } catch (error) {
            if (error.code === 'auth/requires-recent-login') {
                safeAlert("セキュリティ保護のため、一度ログアウトし、再度ログインし直してから実行してください。");
            } else {
                safeAlert("アカウントの削除に失敗しました。");
            }
        }
    });
}