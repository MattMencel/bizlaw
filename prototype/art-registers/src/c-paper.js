// ---------------------------------------------------------------- C · Paper
// No cast. The Case File is already a folder of documents, service is already a
// stamp, the Second is already a countersignature and the Terms Board is already a
// redlined term sheet — so the register is the mechanics drawn, not dressed.
function rowC(t) {
  const silent = t.ours === null && t.theirs === null;
  const asp = t.asp === null ? "" : `<div class="margin">Dana asked: ${t.aspLabel}</div>`;
  if (silent) return `<tr><td class="k">${t.k}</td>
    <td colspan="2" class="silent">Not addressed in this draft, and not in their Day 2 offer.${
      t.asp !== null ? ` <span class="margin">Dana asked: ${t.aspLabel}</span>` : ""}</td></tr>`;
  return `<tr>
    <td class="k">${t.k}${asp}</td>
    <td><span class="ours">${t.ourLabel}</span></td>
    <td>${t.theirLabel === null ? `<span class="silent">silent</span>`
        : `<span class="struck">${t.theirLabel}</span>`}</td>
  </tr>`;
}

function renderC() {
  const q = quote(), b = bandOf();
  const marks = Array.from({ length: BEAT.exchange.budget }, (_, i) =>
    `<span class="mark ${i < BEAT.exchange.spentBefore + q ? "used" : ""}"></span>`).join("");

  const docs = BEAT.exhibits.map(e => {
    const on = !!S.riding[e.id], dud = on && !relevant(e);
    return `<button class="doc ${on ? "clipped" : ""}" data-ex="${e.id}">
      ${on ? `<span class="tab">EXHIBIT</span>` : `<span class="tab" style="background:#8a8073">TAB</span>`}
      <div class="t">${e.name}</div>
      <div class="s">${e.from} · bears on ${e.bears.join(", ")}</div>
      ${on ? `<div class="note">${dud
          ? "Clipped to a draft that says nothing about " + e.bears.join(" or ") +
            ". It still costs a mark and Arrowmark still gets a copy."
          : "Clipped. Served on Arrowmark when this executes."}</div>` : ""}
    </button>`;
  }).join("");

  const rows = docketRows();
  return `<div class="reg-c">
    <div class="file">
      <h4>Case File · Kestrel</h4>
      ${docs}
      <div class="doc" style="cursor:default">
        <span class="tab" style="background:#1f4f8a">SERVED</span>
        <div class="t">Arrowmark internal memo, 14 Feb</div>
        <div class="s">Served by Arrowmark, Day 3</div>
        <div class="note" style="color:#1f4f8a">Served on you. Read it; you cannot clip it —
          a served page carries knowledge, never a tab.</div>
      </div>
    </div>

    <div class="sheet">
      <div class="draftmark"><span class="stamp big">Draft — not executed</span></div>
      <div class="lh">
        <div class="firm">Kestrel &amp; Co.</div>
        <div class="meta">Day ${BEAT.day} of ${BEAT.days}<br>Plaintiff<br>Drawn by ${BEAT.offer.by}</div>
      </div>
      <div class="caption">
        <div class="v">${BEAT.sim}</div>
        <div class="sub">Term sheet · redlined against Arrowmark's offer of Day 2</div>
      </div>

      <table class="terms">
        <tr><th>Term</th><th>Kestrel proposes</th><th>Arrowmark, Day 2</th></tr>
        <tr><td class="k">Payment<div class="margin">Dana asked: $250,000</div></td>
          <td><span class="ours">${money(BEAT.offer.money)}</span></td>
          <td><span class="struck">$60,000</span></td></tr>
        ${BEAT.terms.slice(1).map(rowC).join("")}
      </table>

      <div class="sig">
        <div>
          <div class="line"><span class="hand">Priya Nair</span></div>
          <div class="cap">${BEAT.offer.by} · drawn ${BEAT.offer.staged}</div>
        </div>
        <div class="open">
          <div class="line"></div>
          <div class="cap">Countersignature — <b>${seconderList()}</b>.<br>
            Not yours to sign. You drew it.</div>
        </div>
      </div>

      <div class="price">Exchange marks, Day ${BEAT.day} ${marks}
        <span>This execution: ${q} — the sheet, plus ${riding().length} exhibit${riding().length === 1 ? "" : "s"} clipped to it, quoted as one price.</span>
      </div>
    </div>

    <div>
      <div class="pane">
        <h4>Docket · Day ${BEAT.day}</h4>
        ${rows.length ? rows.map(r => `<div class="row">${r.what}
            <div class="m">Day ${r.day} · ${r.who}${r.cost ? ` · ${r.cost} mark${r.cost > 1 ? "s" : ""}` : ""} · ${r.lands}</div>
          </div>`).join("") : `<div class="empty">${BEAT.docketEmptyCopy}</div>`}
      </div>
      <div class="memo">
        <div class="hd">Memorandum · from the client · Day ${BEAT.day}</div>
        <div class="body">“${b.line}”</div>
        <div class="hd by" style="border:0;margin:10px 0 0;padding:0">
          Dana Whitfield · taken at Consult, 1 mark</div>
        <div class="st"><span class="stamp ${S.band === "ready" ? "blue" : ""}">${b.word}</span></div>
      </div>
    </div>
  </div>`;
}
