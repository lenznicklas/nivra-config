.pragma library

function score(app, query) {
    const name = (app.name || "").toLowerCase();
    const q = query.trim().toLowerCase();
    if (!q) return 0;
    if (name === q) return 1000;
    if (name.startsWith(q)) return 800 - name.length;
    if (name.includes(q)) return 600 - name.indexOf(q);
    const details = [app.genericName || "", app.comment || "",
                     (app.keywords || []).join(" "), app.id || ""].join(" ").toLowerCase();
    const terms = q.split(/\s+/);
    if (terms.every(term => name.includes(term) || details.includes(term)))
        return 300 + terms.filter(term => name.includes(term)).length * 50;
    // Subsequence matching makes abbreviations like "ffx" find Firefox.
    let cursor = 0;
    for (let i = 0; i < name.length && cursor < q.length; ++i)
        if (name[i] === q[cursor]) ++cursor;
    return cursor === q.length ? 100 - name.length : -1;
}

function suggestions(app, recentIds) {
    const recent = recentIds.indexOf(app.id);
    if (recent >= 0) return 200 - recent;
    const preferred = ["strata", "kitty", "firefox", "zen", "files", "settings"];
    const identity = ((app.id || "") + " " + (app.name || "")).toLowerCase();
    const favorite = preferred.findIndex(name => identity.includes(name));
    return favorite >= 0 ? 100 - favorite : 0;
}
